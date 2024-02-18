// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameTest is Test {
  Game public game;
  string[] public characterNames =
    ["Anya", "Taylor", "Joy", "Joseph", "Gordon", "Lewitt", "Batman", "Superman", "Spiderman", "Ironman"];

  function setUp() public {
    game = new Game();
  }

  function testOwnerIsSetCorrectly() public {
    assertEq(address(this), game.owner());
  }

  function testOnlyOwnerCanCreateNewBoss() public {
    vm.prank(address(0));
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0)));
    game.makeNewBoss("gujju", 10_000);
  }

  function testNewCharacterCreation() public {
    vm.roll(50);
    uint256 _power = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(20),
          block.timestamp,
          address(1),
          block.prevrandao //this is 0 during testing
        )
      )
    );

    uint256 _nameIndex = _power % characterNames.length;
    Game.Character memory _newChar =
      Game.Character({name: characterNames[_nameIndex], power_left: _power, experience: 0, created: true, dead: false});
    vm.expectEmit();
    vm.prank(address(1));
    emit Game.NewCharacterCreated(address(1), _newChar);
    game.createNewCharacter();

    assertGt(game.getUsersCharacter(address(1)).power_left, 0);
  }

  function testUnableToCreateCharacterIfItsAlive() public {
    vm.roll(50);
    uint256 _power = uint256(keccak256(abi.encodePacked(blockhash(20), block.timestamp, address(1), block.prevrandao)));

    uint256 _nameIndex = _power % characterNames.length;
    Game.Character memory _newChar =
      Game.Character({name: characterNames[_nameIndex], power_left: _power, experience: 0, created: true, dead: false});
    vm.expectEmit();
    vm.startPrank(address(1));
    emit Game.NewCharacterCreated(address(1), _newChar);
    game.createNewCharacter();

    assertGt(game.getUsersCharacter(address(1)).power_left, 0);
    vm.expectRevert(abi.encodeWithSelector(Game.CharacterAlreadyCreated.selector));
    game.createNewCharacter();
    vm.stopPrank();
  }

  function testRevertOnGetUsersCharacterWhenItDoesntExist() public {
    vm.expectRevert(Game.CharacterNotCreated.selector);
    assertEq(game.getUsersCharacter(address(1)).power_left, 0);
  }
}
