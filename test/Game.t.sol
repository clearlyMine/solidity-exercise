// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Game} from "../src/Game.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GameTest is Test {
  Game public game;
  string[] public characterNames =
    ["Anya", "Taylor", "Joy", "Joseph", "Gordon", "Lewitt", "Batman", "Superman", "Spiderman", "Ironman"];
  Game.Character private _gujjuBoss =
    Game.Character({name: "gujju", powerLeft: 18_417_920_234_273_413_000, experience: 0, created: true, dead: false});

  function setUp() public {
    game = new Game();
    vm.roll(50);
  }

  function testOwnerIsSetCorrectly() public {
    assertEq(address(this), game.owner());
  }

  function testOnlyOwnerCanCreateNewBoss() public {
    vm.prank(address(0));
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0)));
    game.makeNewBossWithRandomPowers("gujju");
  }

  function testNewCharacterCreation() public {
    Game.Character memory _newChar = Game.Character({
      name: "Superman",
      powerLeft: 1_730_191_093_711_958_967,
      experience: 0,
      created: true,
      dead: false
    });

    vm.prank(address(1));
    vm.expectEmit();
    emit Game.NewCharacterCreated(address(1), _newChar);
    game.createNewCharacter();
  }

  function testDontReCreateCharacter() public {
    vm.startPrank(address(1));
    game.createNewCharacter();

    vm.expectRevert(abi.encodeWithSelector(Game.CharacterAlreadyCreated.selector, address(1)));
    game.createNewCharacter();
    vm.stopPrank();
  }

  function testRevertOnGetUsersCharacterWhenItDoesntExist() public {
    vm.expectRevert(abi.encodeWithSelector(Game.CharacterNotCreated.selector, address(1)));
    game.getUsersCharacter(address(1));
  }

  function testCanAttackBoss() public {
    //create boss
    game.makeNewBossWithRandomPowers("gujju");
    vm.roll(52);

    //create character
    vm.startPrank(address(1));
    game.createNewCharacter();
    vm.roll(53);

    Game.Character memory _char =
      Game.Character({name: "Joy", powerLeft: 341_403_779_608_662_062, experience: 0, created: true, dead: false});

    //attack boss
    vm.expectEmit();
    emit Game.BossAttacked(_gujjuBoss, _char, address(1));
    game.attackBoss();

    Game.Character memory _newChar = game.getUsersCharacter(address(1));
    (, uint256 bossPowerLeft,,, bool bossDead) = game.currentBoss();
    assertEq(bossPowerLeft, _gujjuBoss.powerLeft - _char.powerLeft);
    assert(!bossDead);
    assertEq(_newChar.powerLeft, _char.powerLeft - _gujjuBoss.powerLeft / 100);
    assert(!_newChar.dead);
  }

  // Takes 20 addresses to kill boss
  function _killBoss() public returns (uint160) {
    game.makeNewRandomBoss();
    // (, uint256 bossPowerLeft,,,) = game.currentBoss();
    // uint160 player_index = 0;
    // uint256 currentTotal = 0;
    for (uint160 i = 1; i <= 20; i++) {
      // while (currentTotal < bossPowerLeft) {
      // vm.startPrank(address(++player_index));
      vm.startPrank(address(i));
      game.createNewCharacter();
      vm.stopPrank();
      // currentTotal += game.getUsersCharacter(address(player_index)).powerLeft;
    }
    vm.roll(52);
    // for (uint160 i = 1; i <= player_index; i++) {
    for (uint160 i = 1; i <= 20; i++) {
      vm.startPrank(address(i));
      game.attackBoss();
      vm.stopPrank();
    }
    // return player_index;
    return 20;
  }

  function testKillingBossGivesReward() public {
    _killBoss();
    vm.roll(54);
    assertEq(game.canClaimReward(address(20)), 2);
  }

  function testCanClaimReward() public {
    _killBoss();
    vm.roll(53);
    //get experience prior to claiming reward
    Game.Character memory _char = game.getUsersCharacter(address(20));
    vm.startPrank(address(20));
    game.claimReward();
    Game.Character memory _char2 = game.getUsersCharacter(address(20));

    assertGt(_char2.experience, _char.experience);
  }

  function testCanAttackBossInSubsequentBlocks() public {
    //create boss
    game.makeNewBossWithRandomPowers("gujju");
    vm.roll(52);

    //create character
    vm.startPrank(address(1));
    game.createNewCharacter();
    vm.roll(53);
    Game.Character memory _char =
      Game.Character({name: "Joy", powerLeft: 341_403_779_608_662_062, experience: 0, created: true, dead: false});

    //attack boss
    vm.expectEmit();
    emit Game.BossAttacked(_gujjuBoss, _char, address(1));
    game.attackBoss();

    //re-attack boss
    vm.roll(54);
    Game.Character memory _boss =
      Game.Character({name: "gujju", powerLeft: 18_076_516_454_664_750_938, experience: 0, created: true, dead: false});
    _char = Game.Character({
      name: "Joy",
      powerLeft: 157_224_577_265_927_932,
      experience: 3_414_037_796_086_620,
      created: true,
      dead: false
    });
    vm.expectEmit();
    emit Game.BossAttacked(_boss, _char, address(1));
    game.attackBoss();

    Game.Character memory _newChar = game.getUsersCharacter(address(1));
    (, uint256 bossPowerLeft,,, bool bossDead) = game.currentBoss();
    assertEq(bossPowerLeft, 17_919_291_877_398_823_006);
    assert(!bossDead);
    assertEq(_newChar.powerLeft, 0);
    assert(_newChar.dead);
  }

  function testCannotAttackBossWithoutCharacter() public {
    //create boss
    game.makeNewBossWithRandomPowers("gujju");

    //create character
    vm.roll(52);
    vm.startPrank(address(1));

    //attack boss
    vm.expectRevert(abi.encodeWithSelector(Game.CharacterNotCreated.selector, address(1)));
    game.attackBoss();
  }

  function testCannotAttackBossWhenBossIsNotCreated() public {
    //create character
    vm.roll(52);
    vm.startPrank(address(1));
    game.createNewCharacter();

    //attack boss
    vm.expectRevert(Game.BossNotCreated.selector);
    game.attackBoss();
    vm.stopPrank();
  }

  // function testCannotAttackBossWhenBossIsDead() public {
  //   //create boss
  //   game.makeNewBossWithRandomPowers("gujju");
  //   Game.Character memory _boss = Game.Character({
  //     name: "gujju",
  //     powerLeft: 18_417_920_234_273_413_000,
  //     experience: 0,
  //     created: true,
  //     dead: false
  //   });
  //   vm.roll(52);
  //
  //   //create character
  //   vm.startPrank(address(1));
  //   game.createNewCharacter();
  //   Game.Character memory _char = Game.Character({
  //     name: "Joy",
  //     powerLeft: 341_403_779_608_662_062,
  //     experience: 0,
  //     created: true,
  //     dead: false
  //   });
  //
  //   //attack boss
  //   vm.expectRevert(Game.BossIsDead.selector);
  //   game.attackBoss();
  //   vm.stopPrank();
  // }

  function testCannotAttackBossTwiceInTheSameBlock() public {
    //create boss
    game.makeNewBossWithRandomPowers("gujju");
    vm.roll(52);

    //create character
    vm.startPrank(address(1));
    game.createNewCharacter();
    vm.roll(53);

    Game.Character memory _char =
      Game.Character({name: "Joy", powerLeft: 341_403_779_608_662_062, experience: 0, created: true, dead: false});
    //attack boss
    vm.expectEmit();
    emit Game.BossAttacked(_gujjuBoss, _char, address(1));
    game.attackBoss();

    vm.expectRevert(abi.encodeWithSelector(Game.CharacterAlreadyWorking.selector, address(1)));
    game.attackBoss();
  }

  function _healingSetUp() public returns (Game.Character memory _char) {
    vm.startPrank(address(1));
    game.createNewCharacter();
    _char = Game.Character({name: "Joy", powerLeft: 341_403_779_608_662_062, experience: 0, created: true, dead: false});
    vm.stopPrank();
    vm.roll(51);
  }

  function testCanHealOthers() public {
    game.makeNewBossWithRandomPowers("gujju");
    vm.roll(52);
    vm.startPrank(address(1));
    game.createNewCharacter();
    vm.stopPrank();
    vm.startPrank(address(2));
    game.createNewCharacter();
    vm.stopPrank();

    vm.roll(53);

    vm.startPrank(address(1));
    game.attackBoss();
    vm.roll(54);

    game.healCharacter(address(2), 3);
    vm.stopPrank();

    assert(game.getUsersCharacter(address(2)).powerLeft > 0);
  }

  function testCannotHealOneself() public {
    vm.startPrank(address(1));
    vm.expectRevert(abi.encodeWithSelector(Game.CharacterCannotHealOneself.selector, address(1)));
    game.healCharacter(address(1), 1);
  }

  function testCannotHealWithZeroPoints() public {
    vm.startPrank(address(1));
    vm.expectRevert(abi.encodeWithSelector(Game.InvalidInput.selector));
    game.healCharacter(address(2), 0);
  }

  function testCannotHealWhenUninitialized() public {
    _healingSetUp();
    vm.startPrank(address(2));
    vm.expectRevert(abi.encodeWithSelector(Game.CharacterNotCreated.selector, address(2)));
    game.healCharacter(address(1), 1);
  }

  function testCannotHealWhenDead() public {
    //create boss
    game.makeNewBossWithRandomPowers("gujju");
    vm.roll(52);
    vm.startPrank(address(2));
    game.createNewCharacter();
    vm.stopPrank();

    //create character
    vm.startPrank(address(1));
    game.createNewCharacter();

    vm.roll(53);
    //attack boss
    game.attackBoss();

    //re-attack boss-character will die here
    vm.roll(54);
    game.attackBoss();

    vm.roll(55);
    vm.expectRevert(abi.encodeWithSelector(Game.CharacterIsDead.selector, address(1)));
    game.healCharacter(address(2), 1);
  }

  function testCannotHealWhenWorking() public {
    game.makeNewBossWithRandomPowers("gujju");
    _healingSetUp();
    vm.startPrank(address(2));
    game.createNewCharacter();
    vm.stopPrank();

    vm.startPrank(address(3));
    game.createNewCharacter();
    vm.stopPrank();

    vm.roll(52);
    vm.startPrank(address(1));
    game.attackBoss();

    vm.roll(53);

    game.healCharacter(address(2), 1);
    vm.expectRevert(abi.encodeWithSelector(Game.CharacterAlreadyWorking.selector, address(1)));
    game.healCharacter(address(3), 1);
    vm.stopPrank();
  }

  function testCannotHealWhenOtherUninitialized() public {
    vm.startPrank(address(1));
    vm.expectRevert(abi.encodeWithSelector(Game.CharacterNotCreated.selector, address(2)));
    game.healCharacter(address(2), 1);
  }

  function testCannotHealWhenOtherWorking() public {
    game.makeNewRandomBoss();
    vm.startPrank(address(3));
    game.createNewCharacter();
    vm.stopPrank();

    vm.startPrank(address(2));
    game.createNewCharacter();
    vm.roll(51);
    game.attackBoss();
    vm.stopPrank();

    vm.startPrank(address(1));
    vm.expectRevert(abi.encodeWithSelector(Game.CharacterAlreadyWorking.selector, address(2)));
    game.healCharacter(address(2), 1);
    vm.stopPrank();
  }

  function testCannotHealWithNoExperience() public {
    _healingSetUp();

    vm.startPrank(address(2));
    game.createNewCharacter();
    vm.roll(52);

    vm.expectRevert(abi.encodeWithSelector(Game.NotEnoughExperience.selector, address(2)));
    game.healCharacter(address(1), 1);
    vm.stopPrank();
  }

  function testCannotHealWithLessExperience() public {
    game.makeNewRandomBoss();
    _healingSetUp();

    vm.startPrank(address(2));
    game.createNewCharacter();
    vm.roll(52);

    vm.stopPrank();

    vm.startPrank(address(1));
    game.attackBoss();
    vm.roll(53);
    vm.expectRevert(abi.encodeWithSelector(Game.NotEnoughExperience.selector, address(1)));
    game.healCharacter(address(2), 1_730_191_093_711_958_967 + 1);
    vm.stopPrank();
  }
}
