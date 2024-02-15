// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Game.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameTest is Test {
    Game public game;

    function setUp() public {
        game = new Game();
    }

    function testOwnerIsSetCorrectly() public {
        assertEq(address(this), game.owner());
    }

    function testOnlyOwnerCanCreateNewBoss() public {
        vm.prank(address(0));
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(0)
            )
        );
        game.makeNewBoss("gujju", 10000);
    }
}
