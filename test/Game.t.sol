// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";

contract GameTest is Test {
    Game public game;

    function setUp() public {
        game = new Game();
    }

    function testOwnerIsSetCorrectly() public {
        assertEq(address(this), game.owner());
    }
}
