//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// TODO: Implement all user stories and one of the feature request
contract Game is Ownable {
    struct Character {
        string name;
        uint256 power_left;
        uint256 experience;
        bool created;
        bool dead;
    }

    Character public current_boss;
    mapping(address => Character) characters;
    address[] public activePlayers;

    string[] public characterNames = [
        "Anya",
        "Taylor",
        "Joy",
        "Joseph",
        "Gordon",
        "Lewitt",
        "Batman",
        "Superman",
        "Spiderman",
        "Ironman"
    ];

    error CharacterAlreadyCreated();
    error CharacterNotCreated();

    event NewCharacterCreated(address indexed creator, Character character);

    constructor() Ownable(msg.sender) {}

    function makeNewBoss(string calldata _name, uint256 _total_power)
        external
        onlyOwner
    {
        current_boss = Character({
            name: _name,
            power_left: _total_power,
            experience: 0,
            created: true,
            dead: false
        });
    }

    function addToCharacterNamesList(string calldata _newName)
        external
        onlyOwner
    {
        require(bytes(_newName).length != 0);
        characterNames.push(_newName);
    }

    function createNewCharacter() external {
        Character memory _uChar = characters[msg.sender];
        if (_uChar.created) {
            revert CharacterAlreadyCreated();
        }
        uint256 _power = _getRandomPower();
        uint256 _nameIndex = _power % characterNames.length;
        Character memory _newChar = Character({
            name: characterNames[_nameIndex],
            power_left: _power,
            experience: 0,
            created: true,
            dead: false
        });
        characters[msg.sender] = _newChar;
        activePlayers.push(msg.sender);
        emit NewCharacterCreated(msg.sender, _newChar);
    }

    function getUsersCharacter(address adr)
        external
        view
        returns (Character memory)
    {
        Character memory ch = characters[adr];
        if (!ch.created) {
            revert CharacterNotCreated();
        }
        return ch;
    }

    function _getRandomPower() internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 30),
                    block.timestamp,
                    msg.sender,
                    block.prevrandao
                )
            )
        );
    }
}
