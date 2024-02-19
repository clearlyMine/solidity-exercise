// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Game} from "../src/Game.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GameTest is Test {
  Game public game;
  string[] public characterNames =
    ["Anya", "Taylor", "Joy", "Joseph", "Gordon", "Lewitt", "Batman", "Superman", "Spiderman", "Ironman"];

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

    vm.expectRevert(abi.encodeWithSelector(Game.CharacterAlreadyCreated.selector));
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
    Game.Character memory _boss =
      Game.Character({name: "gujju", powerLeft: 18_417_920_234_273_413_000, experience: 0, created: true, dead: false});
    vm.roll(52);

    //create character
    vm.startPrank(address(1));
    game.createNewCharacter();
    Game.Character memory _char =
      Game.Character({name: "Joy", powerLeft: 341_403_779_608_662_062, experience: 0, created: true, dead: false});

    //attack boss
    vm.expectEmit();
    emit Game.BossAttacked(_char);
    game.attackBoss();

    Game.Character memory _newChar = game.getUsersCharacter(address(1));
    (, uint256 bossPowerLeft,,, bool bossDead) = game.currentBoss();
    assertEq(bossPowerLeft, _boss.powerLeft - _char.powerLeft);
    assert(!bossDead);
    assertEq(_newChar.powerLeft, _char.powerLeft - _boss.powerLeft / 100);
    assert(!_newChar.dead);
  }

  function testCanAttackBossInSubsequentBlocks() public {
    //create boss
    game.makeNewBossWithRandomPowers("gujju");
    vm.roll(52);

    //create character
    vm.startPrank(address(1));
    game.createNewCharacter();
    Game.Character memory _char =
      Game.Character({name: "Joy", powerLeft: 341_403_779_608_662_062, experience: 0, created: true, dead: false});

    //attack boss
    vm.expectEmit();
    emit Game.BossAttacked(_char);
    game.attackBoss();

    //re-attack boss
    vm.roll(53);
    _char = Game.Character({name: "Joy", powerLeft: 157_224_577_265_927_932, experience: 0, created: true, dead: false});
    vm.expectEmit();
    emit Game.BossAttacked(_char);
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
    Game.Character memory _char =
      Game.Character({name: "Joy", powerLeft: 341_403_779_608_662_062, experience: 0, created: true, dead: false});

    //attack boss
    vm.expectEmit();
    emit Game.BossAttacked(_char);
    game.attackBoss();

    vm.expectRevert(Game.CharacterAlreadyWorking.selector);
    game.attackBoss();
  }
}
