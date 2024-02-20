//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// TODO: Implement all user stories and one of the feature request
contract Game is Ownable {
  struct Character {
    string name;
    uint64 powerLeft;
    uint128 experience;
    bool created;
    bool dead;
  }

  Character public currentBoss;
  mapping(address userAddress => Character usersCharacter) public characters;
  mapping(address userAddress => uint256 blockNumber) private working;
  address[] public activePlayers;

  string[] public characterNames =
    ["Anya", "Taylor", "Joy", "Joseph", "Gordon", "Lewitt", "Batman", "Superman", "Spiderman", "Ironman"];

  error InvalidInput();

  error CharacterAlreadyCreated(address);
  error CharacterAlreadyWorking(address);
  error CharacterNotCreated(address);
  error CharacterIsDead(address);
  error CharacterCannotHealOneself(address);
  error NotEnoughExperience(address);

  // "Boss is still alive"
  error BossNotDead();
  error BossNotCreated();
  error BossIsDead();
  //  Name cannot be empty
  error EmptyNameSupplied();

  event NewCharacterCreated(address indexed creator, Character character);
  event NewBossCreated(Character boss);
  event BossAttacked(Character attacker);

  constructor() Ownable(msg.sender) {}

  function makeNewBoss(string memory _name, uint64 _totalPower) external onlyOwner {
    _makeNewBoss(_name, _totalPower);
  }

  function _makeNewBoss(string memory _name, uint64 _totalPower) internal {
    _revertOnAliveBoss();
    currentBoss = Character({name: _name, powerLeft: _totalPower, experience: 0, created: true, dead: false});
    emit NewBossCreated(currentBoss);
  }

  function makeNewBossWithRandomPowers(string calldata _name) external onlyOwner {
    _revertOnAliveBoss();
    _makeNewBossWithRandomPowers(_name);
  }

  function _makeNewBossWithRandomPowers(string calldata _name) internal {
    _revertOnAliveBoss();
    _makeNewBoss(_name, _getRandomPower() * 10);
  }

  function makeNewRandomBoss() external onlyOwner {
    _makeNewRandomBoss();
  }
  function _makeNewRandomBoss() internal {
    _revertOnAliveBoss();
    uint64 _pow = _getRandomPower() * 10;
    string memory _name = characterNames[_pow % characterNames.length];
    _makeNewBoss(_name, _pow);
  }

  function _revertOnUninitializedBoss() internal view {
    if (!currentBoss.created) {
      revert BossNotCreated();
    }
  }

  function _revertOnAliveBoss() internal view {
    if (currentBoss.created && !currentBoss.dead && currentBoss.powerLeft != uint256(0)) {
      revert BossNotDead();
    }
  }

  function _revertOnDeadBoss() internal view {
    if (currentBoss.dead || currentBoss.powerLeft == uint256(0)) {
      revert BossIsDead();
    }
  }

  function addToCharacterNamesList(string calldata _newName) external onlyOwner {
    if (bytes(_newName).length != 0) {
      revert EmptyNameSupplied();
    }
    characterNames.push(_newName);
  }

  function createNewCharacter() external {
    if (characters[msg.sender].created) {
      revert CharacterAlreadyCreated(msg.sender);
    }
    uint64 _power = _getRandomPower();
    uint256 _nameIndex = _power % characterNames.length;
    Character memory _newChar =
      Character({name: characterNames[_nameIndex], powerLeft: _power, experience: 0, created: true, dead: false});
    characters[msg.sender] = _newChar;
    activePlayers.push(msg.sender);
    working[msg.sender] = block.number;
    emit NewCharacterCreated(msg.sender, _newChar);
  }

  function getUsersCharacter(address adr) external view returns (Character memory) {
    Character memory ch = characters[adr];
    if (!ch.created) {
      revert CharacterNotCreated(adr);
    }
    return ch;
  }

  function _checkIfCharacterIsAvailableToWork(Character memory _toCheck) internal view {
    _revertOnCharacterNotCreated(_toCheck);
    if (_toCheck.dead) {
      revert CharacterIsDead(msg.sender);
    }
    if (working[msg.sender] >= block.number) {
      revert CharacterAlreadyWorking(msg.sender);
    }
  }

  function _revertOnCharacterNotCreated(Character memory _toCheck) internal view {
    if (!_toCheck.created) {
      revert CharacterNotCreated(msg.sender);
    }
  }

  function attackBoss() external {
    _revertOnUninitializedBoss();
    _revertOnDeadBoss();
    Character storage _uChar = characters[msg.sender];
    _checkIfCharacterIsAvailableToWork(_uChar);
    emit BossAttacked(_uChar);
    working[msg.sender] = block.number;
    uint64 charP = _uChar.powerLeft;
    uint64 bP = currentBoss.powerLeft;

    if (bP <= charP) {
      currentBoss.powerLeft = 0;
      currentBoss.dead = true;
    } else {
      currentBoss.powerLeft -= charP;
    }
    bP /= 100;
    if (charP <= bP) {
      _uChar.powerLeft = 0;
      _uChar.dead = true;
    } else {
      _uChar.powerLeft -= bP;
    }

    if (currentBoss.dead) {
      _makeNewRandomBoss();
    }
  }

  function healCharacter(address adr, uint128 points) external {
    if (adr == msg.sender) {
      revert CharacterCannotHealOneself(msg.sender);
    }
    if (points == 0) {
      revert InvalidInput();
    }

    Character storage _toHeal = characters[adr];
    if (!_toHeal.created) {
      revert CharacterNotCreated(adr);
    }
    if (working[adr] >= block.number) {
      revert CharacterAlreadyWorking(adr);
    }
    Character storage _ownCharacter = characters[msg.sender];
    _checkIfCharacterIsAvailableToWork(_ownCharacter);
    if (_ownCharacter.experience < points) {
      revert NotEnoughExperience(msg.sender);
    }
    working[msg.sender] = block.number;
    _ownCharacter.experience -= points;
    _toHeal.powerLeft += uint64(points);
  }

  function _getRandomPower() internal view returns (uint64) {
    return uint64(
      bytes8(keccak256(abi.encodePacked(blockhash(block.number - 30), block.timestamp, msg.sender, block.prevrandao)))
    ) / 10;
  }
}
