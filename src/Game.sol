//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// TODO: Implement all user stories and one of the feature request
contract Game is Ownable {
    uint256 public x;

    constructor() Ownable(msg.sender) {}
}
