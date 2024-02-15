//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// TODO: Implement all user stories and one of the feature request
contract Game is Ownable {
    struct Boss {
        string name;
        uint256 power_left;
    }
    Boss public current_boss;

    constructor() Ownable(msg.sender) {}

    function makeNewBoss(
        string calldata _name,
        uint256 _total_power
    ) public onlyOwner {
        current_boss = Boss({name: _name, power_left: _total_power});
    }
}
