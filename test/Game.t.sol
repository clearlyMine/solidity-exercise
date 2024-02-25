// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Game} from "../src/Game.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GameTest is Test {
  Game public game;
  string[] public characterNames =
    ["Anya", "Taylor", "Joy", "Joseph", "Gordon", "Lewitt", "Batman", "Superman", "Spiderman", "Ironman"];
  Game.Character private _gujjuBoss = Game.Character({
    name: "gujju",
    hp: 18_417_920_234_273_413_000,
    damage: 0,
    xp: 0,
    level: 1,
    created: true,
    dead: false
  });

  function setUp() public {
    game = new Game(3_211_651_848_984_984_460, 3_211_651_848_984_984_460 * 2);
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
      hp: 1_730_191_093_711_958_967,
      name: "Gordon",
      hp: 1_019_749_324_495_719_894,
      damage: 0,
      xp: 0,
      level: 1,
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
      Game.Character({name: "Joy", hp: 341_403_779_608_662_062, damage: 0, xp: 0, level: 1, created: true, dead: false});
    Game.Character memory _char = Game.Character({
      name: "Gordon",
      hp: 1_019_749_324_495_719_894,
      damage: 0,
      xp: 0,
      level: 1,
      created: true,
      dead: false
    });

    //attack boss
    vm.expectEmit();
    emit Game.BossAttacked(_gujjuBoss, _char, address(1));
    game.attackBoss();

    Game.Character memory _newChar = game.getUsersCharacter(address(1));
    (,, uint256 bossDamage,,,, bool bossDead) = game.currentBoss();

    assertEq(bossDamage, _char.hp);
    assert(!bossDead);
    assertEq(_newChar.damage, _gujjuBoss.hp / 100);
    assert(!_newChar.dead);
  }

  function testAttackingBossGivesXp() public {
    //create boss
    game.makeNewBossWithRandomPowers("gujju");
    vm.roll(52);

    //create character
    vm.startPrank(address(1));
    game.createNewCharacter();
    vm.roll(53);

    Game.Character memory _char = Game.Character({
      name: "Gordon",
      hp: 1_019_749_324_495_719_894,
      damage: 0,
      xp: 0,
      level: 1,
      created: true,
      dead: false
    });

    //attack boss
    vm.expectEmit();
    emit Game.BossAttacked(_gujjuBoss, _char, address(1));
    game.attackBoss();
    Game.Character memory _newChar1 = game.getUsersCharacter(address(1));
    assertEq(_newChar1.xp, 10_197_493_244_957_198);
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
    //get xp prior to claiming reward
    Game.Character memory _char = game.getUsersCharacter(address(20));
    vm.startPrank(address(20));
    game.claimReward();
    Game.Character memory _char2 = game.getUsersCharacter(address(20));

    assertGt(_char2.xp, _char.xp);
  }

  function testCanAttackBossInSubsequentBlocks() public {
    //create boss
    game.makeNewBossWithRandomPowers("gujju");
    vm.roll(52);

    //create character
    vm.startPrank(address(1));
    game.createNewCharacter();
    vm.roll(53);
    Game.Character memory _char = Game.Character({
      name: "Gordon",
      hp: 1_019_749_324_495_719_894,
      damage: 0,
      xp: 0,
      level: 1,
      created: true,
      dead: false
    });

    //attack boss
    vm.expectEmit();
    emit Game.BossAttacked(_gujjuBoss, _char, address(1));
    game.attackBoss();

    //re-attack boss
    vm.roll(54);
    Game.Character memory _boss = Game.Character({
      name: "gujju",
      hp: 18_417_920_234_273_413_000,
      damage: 341_403_779_608_662_062,
      xp: 0,
      level: 1,
      created: true,
      dead: false
    });
    _char = Game.Character({
      name: "Gordon",
      hp: 1_019_749_324_495_719_894,
      damage: 154_568_357_050_665_723,
      xp: 10_197_493_244_957_198,
      level: 1,
      created: true,
      dead: false
    });
    vm.expectEmit();
    emit Game.BossAttacked(_boss, _char, address(1));
    game.attackBoss();

    Game.Character memory _newChar = game.getUsersCharacter(address(1));
    (, uint256 bossHp, uint256 bossDamage,,,, bool bossDead) = game.currentBoss();
    assertEq(bossHp - bossDamage, 17_919_291_877_398_823_006);
    assert(!bossDead);
    assertEq(_newChar.hp, _newChar.damage);
    assert(_newChar.dead);
    assertEq(_newChar.hp, 1_019_749_324_495_719_894);
    assert(!_newChar.dead);
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
  //     xp: 0,
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
  //     xp: 0,
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

    Game.Character memory _char = Game.Character({
      name: "Gordon",
      hp: 1_019_749_324_495_719_894,
      damage: 0,
      xp: 0,
      level: 1,
      created: true,
      dead: false
    });
    //attack boss
    vm.expectEmit();
    emit Game.BossAttacked(_gujjuBoss, _char, address(1));
    game.attackBoss();

    vm.expectRevert(abi.encodeWithSelector(Game.CharacterAlreadyWorking.selector, address(1)));
    game.attackBoss();
  }

  function testLevelDoesntChangeIfThresholdIsntReachedOnXpIncrease() public {
    game.makeNewRandomBoss();

    vm.startPrank(address(1));
    game.createNewCharacter();
    vm.roll(52);
    game.attackBoss();

    vm.stopPrank();
    Game.Character memory _char = game.getUsersCharacter(address(1));
    assertGt(_char.xp, 0);
    assertEq(_char.level, 1);
  }

  function testLevelDoesntChangeIfThresholdIsntReachedOnXpDecrease() public {
    Game _localGame = new Game(403_779_608_662_062, 1_730_191_093_711_958_967 * 2);
    _localGame.makeNewBoss("Gujju", 4_037_796_086_620_620_000);

    vm.startPrank(address(1));
    _localGame.createNewCharacter();
    Game.Character memory _lastChar;
    uint256 _blockNum = 52;
    while (!_lastChar.dead) {
      vm.roll(_blockNum++);
      _localGame.attackBoss();
      _lastChar = _localGame.getUsersCharacter(address(1));
    }

    vm.stopPrank();

    assert(_lastChar.dead);
    assertEq(_lastChar.level, 2);
  }

  function testLevel1To2UpgradeOnIncreasingXp() public {
    Game _localGame = new Game(403_779_608_662_062, 1_730_191_093_711_958_967 * 2);
    _localGame.makeNewRandomBoss();
    vm.startPrank(address(1));
    _localGame.createNewCharacter();
    vm.roll(51);
    _localGame.attackBoss();
    vm.stopPrank();

    assertEq(_localGame.getUsersCharacter(address(1)).level, 2);
  }

  function testLevel1To2To3UpgradeOnIncreasingXp() public {
    Game _localGame = new Game(403_779_608_662_062, 17_301_910_937_119_589 + 3);
    _localGame.makeNewRandomBoss();
    vm.startPrank(address(1));
    _localGame.createNewCharacter();
    vm.roll(51);
    _localGame.attackBoss();
    vm.roll(52);
    _localGame.attackBoss();
    vm.stopPrank();

    assertEq(_localGame.getUsersCharacter(address(1)).level, 3);
  }

  //With the current game xp increasing this will never happen, as the character earns more xp than it
  //loses every time
  // function testLevelDowngradeOnDecreasingXp() public {
  //   Game _localGame = new Game(403_779_608_662_062, 17301910937119589 + 3);
  //   _localGame.makeNewBoss("x", 3333333333333333333);
  //
  //   vm.startPrank(address(1));
  //   _localGame.createNewCharacter();
  //   vm.roll(51);
  //   _localGame.attackBoss();
  //   vm.stopPrank();
  //   Game.Character memory _char = _localGame.getUsersCharacter(address(1));
  //   assertEq(_char.level, 2);
  //
  //   vm.startPrank(address(1));
  //   vm.roll(52);
  //   _localGame.attackBoss();
  //   vm.stopPrank();
  //   assertEq(_char.level, 1);
  // }

  function _healingSetUp() public returns (Game.Character memory _char) {
    vm.startPrank(address(1));
    game.createNewCharacter();
    _char =
      Game.Character({name: "Joy", hp: 341_403_779_608_662_062, damage: 0, xp: 0, level: 1, created: true, dead: false});
    vm.stopPrank();
    vm.roll(51);
  }

  function testCanHealOthers() public {
    Game _localGame = new Game(4_444_444, 9_999_999_999_999);
    _localGame.makeNewBoss("gujju", 494_949_494_949_494_949);
    vm.roll(52);
    vm.startPrank(address(1));
    _localGame.createNewCharacter();
    vm.stopPrank();
    vm.startPrank(address(2));
    _localGame.createNewCharacter();
    vm.stopPrank();

    vm.roll(53);

    vm.startPrank(address(1));
    _localGame.attackBoss();
    vm.stopPrank();
    vm.startPrank(address(2));
    _localGame.attackBoss();
    vm.stopPrank();
    vm.roll(54);

    uint64 u2Damage = _localGame.getUsersCharacter(address(2)).damage;

    vm.startPrank(address(1));
    _localGame.healCharacter(address(2), 3);
    vm.stopPrank();

    assertEq(_localGame.getUsersCharacter(address(2)).damage, u2Damage - 3);
  }

  function testCannotHealOneself() public {
    vm.startPrank(address(1));
    vm.expectRevert(abi.encodeWithSelector(Game.InvalidInput.selector, "Character cannot heal oneself"));
    game.healCharacter(address(1), 1);
  }

  function testCannotHealWithZeroPoints() public {
    vm.startPrank(address(1));
    vm.expectRevert(abi.encodeWithSelector(Game.InvalidInput.selector, "Points to be healed cannot be 0"));
    game.healCharacter(address(2), 0);
  }

  function testCannotHealWhenUninitialized() public {
    _healingSetUp();
    vm.startPrank(address(2));
    vm.expectRevert(abi.encodeWithSelector(Game.CharacterNotCreated.selector, address(2)));
    game.healCharacter(address(1), 1);
  }

  function testCanCastFireballSpell() public {
    Game _localGame = new Game(4444, 9999);
    _localGame.makeNewBoss("x", 999_999_999_999_999_999);

    vm.warp(2 days);
    vm.startPrank(address(1));
    _localGame.createNewCharacter();
    vm.roll(51);
    _localGame.attackBoss();
    vm.roll(52);
    _localGame.attackBoss();

    vm.roll(53);
    _localGame.castFireballSpell();
    vm.stopPrank();
  }

  function testCanCastFireballSpellAfter24Hours() public {
    Game _localGame = new Game(4444, 9999);
    _localGame.makeNewBoss("x", 999_999_999_999_999_999);

    vm.warp(2 days);
    vm.startPrank(address(1));
    _localGame.createNewCharacter();
    vm.roll(51);
    _localGame.attackBoss();
    vm.roll(52);
    _localGame.attackBoss();

    vm.roll(53);
    _localGame.castFireballSpell();
    skip(1 days);
    vm.roll(54);
    _localGame.castFireballSpell();
    vm.stopPrank();
  }

  function testCannotCastFireballSpellTwiceWithin24Hours() public {
    Game _localGame = new Game(4444, 9999);
    _localGame.makeNewBoss("x", 999_999_999_999_999_999);

    vm.warp(2 days);
    vm.startPrank(address(1));
    _localGame.createNewCharacter();
    vm.roll(51);
    _localGame.attackBoss();
    vm.roll(52);
    _localGame.attackBoss();

    vm.roll(53);
    _localGame.castFireballSpell();
    vm.roll(54);
    skip(100);
    vm.expectRevert(abi.encodeWithSelector(Game.TimeBound.selector, "Can only cast once per 24 hours"));
    _localGame.castFireballSpell();
    skip(1 days - 101);
    vm.expectRevert(abi.encodeWithSelector(Game.TimeBound.selector, "Can only cast once per 24 hours"));
    _localGame.castFireballSpell();

    vm.stopPrank();
  }

  function testCannotCastFireballSpellBelowLevel3() public {
    Game _localGame = new Game(44_444_444_444, 999_999_999_999_999_999);
    _localGame.makeNewBoss("x", 999_999_999_999_999_999);

    vm.startPrank(address(1));
    _localGame.createNewCharacter();
    vm.roll(51);
    vm.expectRevert(abi.encodeWithSelector(Game.LevelTooLow.selector, "At least level 3 is needed"));
    _localGame.castFireballSpell();
    vm.roll(52);
    _localGame.attackBoss();
    vm.roll(53);
    vm.expectRevert(abi.encodeWithSelector(Game.LevelTooLow.selector, "At least level 3 is needed"));
    _localGame.castFireballSpell();
    vm.roll(54);
    _localGame.attackBoss();
    vm.roll(55);
    vm.expectRevert(abi.encodeWithSelector(Game.LevelTooLow.selector, "At least level 3 is needed"));
    _localGame.castFireballSpell();
    vm.stopPrank();
  }

  function testCannotHealWhenLevel1() public {
    Game _localGame = new Game(44_444_444_444_444_444_444, 999_999_999_999_000_999_999_999_999);
    _localGame.makeNewBoss("gujju", 494_949_494_949_494_949);
    vm.roll(52);
    vm.startPrank(address(1));
    _localGame.createNewCharacter();
    vm.stopPrank();
    vm.startPrank(address(2));
    _localGame.createNewCharacter();
    vm.stopPrank();

    vm.roll(53);

    vm.startPrank(address(1));
    _localGame.attackBoss();
    vm.stopPrank();
    vm.startPrank(address(2));
    _localGame.attackBoss();
    vm.stopPrank();
    vm.roll(54);

    vm.startPrank(address(1));
    vm.expectRevert(abi.encodeWithSelector(Game.LevelTooLow.selector, "At least level 2 is needed"));
    _localGame.healCharacter(address(2), 3);
    vm.stopPrank();
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
    Game _localGame = new Game(4_444_444, 9_999_999_999_999);
    _localGame.makeNewBossWithRandomPowers("gujju");

    vm.startPrank(address(1));
    _localGame.createNewCharacter();
    vm.stopPrank();

    vm.roll(51);
    vm.startPrank(address(2));
    _localGame.createNewCharacter();
    vm.stopPrank();

    vm.startPrank(address(3));
    _localGame.createNewCharacter();
    vm.stopPrank();

    vm.roll(52);
    vm.startPrank(address(1));
    _localGame.attackBoss();
    vm.stopPrank();

    vm.startPrank(address(2));
    _localGame.attackBoss();
    vm.stopPrank();

    vm.roll(53);

    vm.startPrank(address(1));

    _localGame.healCharacter(address(2), 1);
    vm.expectRevert(abi.encodeWithSelector(Game.CharacterAlreadyWorking.selector, address(1)));
    _localGame.healCharacter(address(3), 1);
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

  function testCannotHealWithNoXp() public {
    _healingSetUp();

    vm.startPrank(address(2));
    game.createNewCharacter();
    vm.roll(52);

    vm.expectRevert(abi.encodeWithSelector(Game.NotEnoughXp.selector, address(2)));
    game.healCharacter(address(1), 1);
    vm.stopPrank();
  }

  function testCannotHealWithLessXp() public {
    game.makeNewRandomBoss();
    _healingSetUp();

    vm.startPrank(address(2));
    game.createNewCharacter();
    vm.roll(52);

    vm.stopPrank();

    vm.startPrank(address(1));
    game.attackBoss();
    vm.roll(53);
    vm.expectRevert(abi.encodeWithSelector(Game.NotEnoughXp.selector, address(1)));
    game.healCharacter(address(2), 1_730_191_093_711_958_967 + 1);
    vm.stopPrank();
  }
}
