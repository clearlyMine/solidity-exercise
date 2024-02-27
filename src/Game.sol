//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBaycToken} from "./IBaycToken.sol";

// TODO: Implement all user stories and one of the feature request
contract Game is Ownable {
  struct Boss {
    uint16 name;
    uint64 hp;
    uint64 damage;
    uint32 reward;
    bool dead;
  }

  struct Character {
    string name;
    uint64 hp;
    uint64 damage;
    uint256 xp;
    uint8 level;
    bool created;
    bool dead;
  }

  uint8 private constant FALSE = 1;
  uint8 private constant TRUE = 2;
  uint128 public level2Points = 0;
  uint128 public level3Points = 0;
  Boss public currentBoss;
  mapping(address userAddress => Character usersCharacter) public characters;
  mapping(address userAddress => uint256 blockNumber) private working;
  mapping(address addr => uint8 bBool) public canClaimReward;
  mapping(address addr => uint256 timestamp) public fireballSpellCastAt;
  address[] public activePlayers;

  string[] public characterNames =
    ["Anya", "Taylor", "Joy", "Joseph", "Gordon", "Lewitt", "Batman", "Superman", "Spiderman", "Ironman"];

  error CannotClaimReward(address);

  error InvalidInput(string);

  error CharacterAlreadyCreated(address);
  error CharacterAlreadyWorking(address);
  error CharacterNotCreated(address);
  error CharacterNotDamaged(address);
  error CharacterIsDead(address);
  error NotEnoughXp(address);

  error LevelTooLow(string);

  error LevelPointsTooLow(string);

  // "Boss is still alive"
  error BossNotDead(Boss boss);
  error BossNotCreated();
  error BossIsDead(Boss boss);
  //  Name cannot be empty
  error EmptyNameSupplied();
  error TimeBound(string);

  event NewCharacterCreated(address indexed creator, Character character);
  event NewBossCreated(Boss boss);
  event BossAttacked(Boss boss, Character attacker, address indexed user);
  event BossKilled(Boss boss, address indexed killer);
  event CanClaimReward(address indexed);
  event CastFireballSpell(Character);

  address baycAddress = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
  IBaycToken baycContract;

  constructor(uint128 l2p, uint128 l3p) Ownable(msg.sender) {
    level2Points = l2p;
    level3Points = l3p;
    baycContract = IBaycToken(baycAddress);
    _makeNewBossWithoutChecks();
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

  function changeBaycAddress(address a) external onlyOwner {
    baycAddress = a;
    baycContract = IBaycToken(baycAddress);
  }

  function makeNewBoss() external onlyOwner {
    _makeNewBoss();
  }

  function makeNewBoss(uint16 _name) external onlyOwner {
    _makeNewBoss(_name);
  }

  function makeNewBoss(uint16 _name, uint64 _hp) external onlyOwner {
    _makeNewBoss(_name, _hp);
  }

  function makeNewBoss(uint16 _name, uint64 _hp, uint32 _reward) external onlyOwner {
    _makeNewBoss(_name, _hp, _reward);
  }

  function _makeNewBoss() private {
    _revertOnAliveBoss();
    _makeNewBossWithoutChecks();
  }

  function _makeNewBoss(uint16 _name) private {
    _revertOnInvalidBossName(_name);
    _revertOnAliveBoss();
    _makeNewBossWithoutChecks(_name);
  }

  function _makeNewBoss(uint16 _name, uint64 _hp) private {
    _revertOnInvalidBossName(_name);
    _revertOnAliveBoss();
    _makeNewBossWithoutChecks(_name, _hp);
  }

  function _makeNewBoss(uint16 _name, uint64 _hp, uint32 _reward) private {
    _revertOnInvalidBossName(_name);
    _revertOnAliveBoss();
    _makeNewBossWithoutChecks(_name, _hp, _reward);
  }

  function _makeNewBossWithoutChecks() private {
    _makeNewBossWithoutChecks(uint16(_getRandomNumber() % 10_000));
  }

  function _makeNewBossWithoutChecks(uint16 _name) private {
    _makeNewBossWithoutChecks(_name, _getRandomPower() * 10);
  }

  function _makeNewBossWithoutChecks(uint16 _name, uint64 _hp) private {
    _makeNewBossWithoutChecks(_name, _hp, uint32(_getRandomNumber()));
  }

  function _makeNewBossWithoutChecks(uint16 _name, uint64 _hp, uint32 _reward) private {
    currentBoss = Boss({name: _name, hp: _hp, damage: 0, reward: _reward, dead: false});
    emit NewBossCreated(currentBoss);
  }

  function _revertOnInvalidBossName(uint16 _name) private pure {
    require(_name >= 0 && _name < 10_000, "Name has to be in the range 0-9,999, as BAYC only has 10,000 NFTs");
  }

  function _revertOnAliveBoss() private view {
    if (!currentBoss.dead) {
      revert BossNotDead(currentBoss);
    }
  }

  function _revertOnDeadBoss() private view {
    if (currentBoss.dead) {
      revert BossIsDead(currentBoss);
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
      Character({name: characterNames[_nameIndex], hp: _power, damage: 0, xp: 0, level: 1, created: true, dead: false});
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

  function _checkIfCharacterIsAvailableToWork(Character memory _toCheck, address adr) private view {
    _revertOnCharacterNotCreated(_toCheck);
    if (_toCheck.dead) {
      revert CharacterIsDead(msg.sender);
    }
    if (working[adr] >= block.number) {
      revert CharacterAlreadyWorking(msg.sender);
    }
  }

  function _revertOnCharacterNotCreated(Character memory _toCheck) private view {
    if (!_toCheck.created) {
      revert CharacterNotCreated(msg.sender);
    }
  }

  function attackBoss() external {
    _revertOnDeadBoss();
    Character storage _uChar = characters[msg.sender];
    _checkIfCharacterIsAvailableToWork(_uChar, msg.sender);
    working[msg.sender] = block.number;
    emit BossAttacked(currentBoss, _uChar, msg.sender);
    uint64 charP = _uChar.hp - _uChar.damage;
    uint64 bP = currentBoss.hp - currentBoss.damage;

    if (bP <= charP) {
      currentBoss.damage = currentBoss.hp;
      currentBoss.dead = true;
    } else {
      currentBoss.damage += charP;
    }
    bP /= 100;
    if (charP <= bP) {
      _uChar.damage = _uChar.hp;
      _uChar.dead = true;
    } else {
      _uChar.damage += bP;
    }

    bool _bossDead = currentBoss.dead;
    uint32 _bossReward = currentBoss.reward;
    bool _charDead = _uChar.dead;
    if ((!_bossDead && !_charDead) || (_bossDead && _charDead)) {
      _uChar.xp += _getRandomNumber() % _bossReward;
    } else if ((_bossDead && !_charDead) || (_bossDead && _charDead)) {
      _uChar.xp += _bossReward;
    }

    if (currentBoss.dead) {
      emit BossKilled(msg.sender);
      emit CanClaimReward(msg.sender);
      canClaimReward[msg.sender] = TRUE;
    }
    _changeCharacterLevel(_uChar);
  }

  function _changeCharacterLevel(Character storage _char) private {
    if (_char.level == 1 && _char.xp >= level2Points) {
      _char.level = 2;
    }
    if (_char.level == 2 && _char.xp >= level3Points) {
      _char.level = 3;
    }
    if (_char.level == 2 && _char.xp < level2Points) {
      _char.level = 1;
    }
    if (_char.level == 3 && _char.xp < level3Points) {
      _char.level = 2;
    }
    if (_char.level == 3 && _char.xp < level2Points) {
      _char.level = 1;
    }
  }

  //Currently gives xp as reward after killing a boss
  function claimReward() external {
    Character storage _char = characters[msg.sender];
    _checkIfCharacterIsAvailableToWork(_char, msg.sender);
    working[msg.sender] = block.number;
    uint8 x = canClaimReward[msg.sender];
    if (x == FALSE || x == 0) {
      revert CannotClaimReward(msg.sender);
    }
    canClaimReward[msg.sender] = FALSE;
    _char.xp += _getRandomPower();
  }

  function _canTheyHeal(address healer, address patient, uint128 pointsToHeal)
    private
    view
    returns (Character storage, Character storage)
  {
    if (patient == healer) {
      revert InvalidInput("Character cannot heal oneself");
    }
    if (pointsToHeal == 0) {
      revert InvalidInput("Points to be healed cannot be 0");
    }

    Character storage _toHeal = characters[patient];
    if (!_toHeal.created) {
      revert CharacterNotCreated(patient);
    }
    if (working[patient] >= block.number) {
      revert CharacterAlreadyWorking(patient);
    }
    Character storage _ownCharacter = characters[msg.sender];
    _checkIfCharacterIsAvailableToWork(_ownCharacter, msg.sender);
    if (_ownCharacter.xp < pointsToHeal) {
      revert NotEnoughXp(msg.sender);
    }
    if (_toHeal.damage == 0) {
      revert CharacterNotDamaged(address(patient));
    }
    if (_ownCharacter.level < 2) {
      revert LevelTooLow("At least level 2 is needed");
    }
    return (_ownCharacter, _toHeal);
  }

  function healCharacter(address adr, uint128 points) external {
    (Character storage _ownCharacter, Character storage _toHeal) = _canTheyHeal(msg.sender, adr, points);
    working[msg.sender] = block.number;
    if (points > _toHeal.damage) {
      _ownCharacter.xp -= _toHeal.damage;
      _toHeal.damage = 0;
    } else {
      _ownCharacter.xp -= points;
      _toHeal.damage -= uint64(points);
    }
  }

  function castFireballSpell() external {
    Character storage _ownCharacter = characters[msg.sender];
    _checkIfCharacterIsAvailableToWork(_ownCharacter, msg.sender);

    if (_ownCharacter.level < 3) {
      revert LevelTooLow("At least level 3 is needed");
    }
    if (fireballSpellCastAt[msg.sender] > (block.timestamp - 1 days)) {
      revert TimeBound("Can only cast once per 24 hours");
    }

    fireballSpellCastAt[msg.sender] = block.timestamp;

    emit CastFireballSpell(_ownCharacter);
  }

  function _getRandomPower() private view returns (uint64) {
    return uint64(_getRandomNumber()) / 10;
  }

  function _getRandomNumber() private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp, msg.sender, block.prevrandao)));
  }
}
