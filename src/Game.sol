//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// TODO: Implement all user stories and one of the feature request
contract Game is Ownable {
  struct Character {
    string name;
    uint64 maxPower;
    uint64 damage;
    uint128 experience;
    uint8 level;
    bool created;
    bool dead;
  }

  uint8 internal constant FALSE = 1;
  uint8 internal constant TRUE = 2;
  uint128 public level2Points = 0;
  uint128 public level3Points = 0;
  Character public currentBoss;
  mapping(address userAddress => Character usersCharacter) public characters;
  mapping(address userAddress => uint256 blockNumber) private working;
  mapping(address addr => uint8 bBool) public canClaimReward;
  address[] public activePlayers;

  string[] public characterNames =
    ["Anya", "Taylor", "Joy", "Joseph", "Gordon", "Lewitt", "Batman", "Superman", "Spiderman", "Ironman"];

  error CannotClaimReward(address);

  error InvalidInput();

  error CharacterAlreadyCreated(address);
  error CharacterAlreadyWorking(address);
  error CharacterNotCreated(address);
  error CharacterNotDamaged(address);
  error CharacterIsDead(address);
  error CharacterCannotHealOneself(address);
  error NotEnoughExperience(address);

  error LevelPointsTooLow(string);

  // "Boss is still alive"
  error BossNotDead();
  error BossNotCreated();
  error BossIsDead();
  //  Name cannot be empty
  error EmptyNameSupplied();

  event NewCharacterCreated(address indexed creator, Character character);
  event NewBossCreated(Character boss);
  event BossAttacked(Character boss, Character attacker, address indexed user);
  event BossKilled(address indexed);
  event CanClaimReward(address indexed);

  constructor(uint128 l2p, uint128 l3p) Ownable(msg.sender) {
    level2Points = l2p;
    level3Points = l3p;
  }

  function setLevel2Points(uint128 l2p) external onlyOwner {
    level2Points = l2p;
  }

  function setLevel3Points(uint128 l3p) external onlyOwner {
    if (l3p > level2Points) {
      revert LevelPointsTooLow("Points needed for getting to level 3 cannot be fewer than level 2");
    }
    level3Points = l3p;
  }

  function makeNewBoss(string memory _name, uint64 _totalPower) external onlyOwner {
    _makeNewBoss(_name, _totalPower);
  }

  function _makeNewBoss(string memory _name, uint64 _totalPower) internal {
    _revertOnAliveBoss();
    currentBoss =
      Character({name: _name, maxPower: _totalPower, damage: 0, experience: 0, level: 1, created: true, dead: false});
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
    if (currentBoss.created && !currentBoss.dead && currentBoss.maxPower > currentBoss.damage) {
      revert BossNotDead();
    }
  }

  function _revertOnDeadBoss() internal view {
    if (currentBoss.dead || currentBoss.maxPower == currentBoss.damage) {
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
    Character memory _newChar = Character({
      name: characterNames[_nameIndex],
      maxPower: _power,
      damage: 0,
      experience: 0,
      level: 1,
      created: true,
      dead: false
    });
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

  function _checkIfCharacterIsAvailableToWork(Character memory _toCheck, address adr) internal view {
    _revertOnCharacterNotCreated(_toCheck);
    if (_toCheck.dead) {
      revert CharacterIsDead(msg.sender);
    }
    if (working[adr] >= block.number) {
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
    _checkIfCharacterIsAvailableToWork(_uChar, msg.sender);
    working[msg.sender] = block.number;
    emit BossAttacked(currentBoss, _uChar, msg.sender);
    uint64 charP = _uChar.maxPower - _uChar.damage;
    uint64 bP = currentBoss.maxPower - currentBoss.damage;

    if (bP <= charP) {
      currentBoss.damage = currentBoss.maxPower;
      currentBoss.dead = true;
      _uChar.experience += bP / 100;
    } else {
      currentBoss.damage += charP;
      _uChar.experience += charP / 100;
    }
    bP /= 100;
    if (charP <= bP) {
      _uChar.damage = _uChar.maxPower;
      _uChar.dead = true;
    } else {
      _uChar.damage += bP;
    }

    if (currentBoss.dead) {
      emit BossKilled(msg.sender);
      emit CanClaimReward(msg.sender);
      _makeNewRandomBoss();
      canClaimReward[msg.sender] = TRUE;
    }
    _changeCharacterLevel(_uChar);
  }

  function _changeCharacterLevel(Character storage _char) private {
    if (_char.level == 1 && _char.experience >= level2Points) {
      _char.level = 2;
    }
    if (_char.level == 2 && _char.experience >= level3Points) {
      _char.level = 3;
    }
    if (_char.level == 2 && _char.experience < level2Points) {
      _char.level = 1;
    }
    if (_char.level == 3 && _char.experience < level3Points) {
      _char.level = 2;
    }
  }

  //Currently gives experience as reward after killing a boss
  function claimReward() external {
    Character storage _char = characters[msg.sender];
    _checkIfCharacterIsAvailableToWork(_char, msg.sender);
    working[msg.sender] = block.number;
    uint8 x = canClaimReward[msg.sender];
    if (x == FALSE || x == 0) {
      revert CannotClaimReward(msg.sender);
    }
    canClaimReward[msg.sender] = FALSE;
    _char.experience += _getRandomPower();
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
    _checkIfCharacterIsAvailableToWork(_ownCharacter, msg.sender);
    if (_ownCharacter.experience < points) {
      revert NotEnoughExperience(msg.sender);
    }
    if (_toHeal.damage == 0) {
      revert CharacterNotDamaged(address(adr));
    }
    working[msg.sender] = block.number;
    if (points > _toHeal.damage) {
      _ownCharacter.experience -= _toHeal.damage;
      _toHeal.damage = 0;
    } else {
      _ownCharacter.experience -= points;
      _toHeal.damage -= uint64(points);
    }
  }

  function _getRandomPower() internal view returns (uint64) {
    return uint64(
      bytes8(keccak256(abi.encodePacked(blockhash(block.number - 30), block.timestamp, msg.sender, block.prevrandao)))
    ) / 10;
  }
}
