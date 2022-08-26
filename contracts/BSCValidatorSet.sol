pragma solidity 0.6.4;
pragma experimental ABIEncoderV2;

import "./System.sol";
import "./lib/BytesToTypes.sol";
import "./lib/Memory.sol";
import "./interface/ILightClient.sol";
import "./interface/ISlashIndicator.sol";
import "./interface/ITokenHub.sol";
import "./interface/IRelayerHub.sol";
import "./interface/IParamSubscriber.sol";
import "./interface/IBSCValidatorSet.sol";
import "./interface/IApplication.sol";
import "./lib/SafeMath.sol";
import "./lib/RLPDecode.sol";
import "./lib/CmnPkg.sol";

contract BSCValidatorSet is IBSCValidatorSet, System, IParamSubscriber, IApplication {

  using SafeMath for uint256;

  using RLPDecode for *;

  // will not transfer value less than 0.1 BNB for validators
  uint256 constant public DUSTY_INCOMING = 1e17;

  uint8 public constant JAIL_MESSAGE_TYPE = 1;
  uint8 public constant VALIDATORS_UPDATE_MESSAGE_TYPE = 0;

  // the precision of cross chain value transfer.
  uint256 public constant PRECISION = 1e10;
  uint256 public constant EXPIRE_TIME_SECOND_GAP = 1000;
  uint256 public constant MAX_NUM_OF_VALIDATORS = 41;

  bytes public constant INIT_VALIDATORSET_BYTES = hex"f9056e80f9056af840940edeb45c1afba171a48ae465430197cbb8e2a10a940edeb45c1afba171a48ae465430197cbb8e2a10a940edeb45c1afba171a48ae465430197cbb8e2a10a64f84094f158ffad57989a3a8ee43e0db94558d862a76a8394f158ffad57989a3a8ee43e0db94558d862a76a8394f158ffad57989a3a8ee43e0db94558d862a76a8364f840948fc21a34aaaf22c9ff8edf193788120a909d207a948fc21a34aaaf22c9ff8edf193788120a909d207a948fc21a34aaaf22c9ff8edf193788120a909d207a64f8409496c154671b745be8ca1000794b360bbd5c6dfcae9496c154671b745be8ca1000794b360bbd5c6dfcae9496c154671b745be8ca1000794b360bbd5c6dfcae64f840944564565acd89dd84e4aeb54f0a81036735d1fe1c944564565acd89dd84e4aeb54f0a81036735d1fe1c944564565acd89dd84e4aeb54f0a81036735d1fe1c64f840945da54722143d8d85c1ebe65c5f1411502385ca07945da54722143d8d85c1ebe65c5f1411502385ca07945da54722143d8d85c1ebe65c5f1411502385ca0764f840940c20ed9b97343a9c9fc705c5fc34d100e81c3b66940c20ed9b97343a9c9fc705c5fc34d100e81c3b66940c20ed9b97343a9c9fc705c5fc34d100e81c3b6664f84094a5664e7a9590f29f6cfb0e3c3ad3979e2f828cb994a5664e7a9590f29f6cfb0e3c3ad3979e2f828cb994a5664e7a9590f29f6cfb0e3c3ad3979e2f828cb964f84094256740477c44ed59dece0cfdab11abe85fe199cf94256740477c44ed59dece0cfdab11abe85fe199cf94256740477c44ed59dece0cfdab11abe85fe199cf64f84094f0d85464be1fd946e48d1ddd64c1b02e8cd8131394f0d85464be1fd946e48d1ddd64c1b02e8cd8131394f0d85464be1fd946e48d1ddd64c1b02e8cd8131364f840946beaeef3675c745ec0b983a9208772494267146c946beaeef3675c745ec0b983a9208772494267146c946beaeef3675c745ec0b983a9208772494267146c64f84094248c10b559c8b91ef55974907b5ada532675f1a394248c10b559c8b91ef55974907b5ada532675f1a394248c10b559c8b91ef55974907b5ada532675f1a364f840941ac0f265258f64cd63a0d0bdcac9b221084c2d20941ac0f265258f64cd63a0d0bdcac9b221084c2d20941ac0f265258f64cd63a0d0bdcac9b221084c2d2064f840948edb4e484bf66e81bc4cec1a608811e1668f6374948edb4e484bf66e81bc4cec1a608811e1668f6374948edb4e484bf66e81bc4cec1a608811e1668f637464f84094750f85c6cbd46f0504c0a4fdb8b5f77cdf506d8294750f85c6cbd46f0504c0a4fdb8b5f77cdf506d8294750f85c6cbd46f0504c0a4fdb8b5f77cdf506d8264f84094b13dc8e1ca7fd5902aa3ce0e4218802b9aebd6cd94b13dc8e1ca7fd5902aa3ce0e4218802b9aebd6cd94b13dc8e1ca7fd5902aa3ce0e4218802b9aebd6cd64f84094ae73b47658a591e8ab5e7cb77865a3d6eda63c0e94ae73b47658a591e8ab5e7cb77865a3d6eda63c0e94ae73b47658a591e8ab5e7cb77865a3d6eda63c0e64f840941fc64cac1c456080ff0315c08c12055792a3b0ff941fc64cac1c456080ff0315c08c12055792a3b0ff941fc64cac1c456080ff0315c08c12055792a3b0ff64f84094bd10cd785e30600c123ff5715f4c3acbff7ea79b94bd10cd785e30600c123ff5715f4c3acbff7ea79b94bd10cd785e30600c123ff5715f4c3acbff7ea79b64f84094bff5efa77e5412e25d05faf2406ac9706967516994bff5efa77e5412e25d05faf2406ac9706967516994bff5efa77e5412e25d05faf2406ac9706967516964f8409488761ab2e00df4e18392539125d604aa0728d8019488761ab2e00df4e18392539125d604aa0728d8019488761ab2e00df4e18392539125d604aa0728d80164";

  uint32 public constant ERROR_UNKNOWN_PACKAGE_TYPE = 101;
  uint32 public constant ERROR_FAIL_CHECK_VALIDATORS = 102;
  uint32 public constant ERROR_LEN_OF_VAL_MISMATCH = 103;
  uint32 public constant ERROR_RELAYFEE_TOO_LARGE = 104;

  uint256 public constant INIT_NUM_OF_CABINETS = 21;
  uint256 public constant EPOCH = 200;

  /*********************** state of the contract **************************/
  Validator[] public currentValidatorSet;
  uint256 public expireTimeSecondGap;
  uint256 public totalInComing;

  // key is the `consensusAddress` of `Validator`,
  // value is the index of the element in `currentValidatorSet`.
  mapping(address =>uint256) public currentValidatorSetMap;
  uint256 public numOfJailed;

  uint256 public constant BURN_RATIO_SCALE = 10000;
  uint256 public constant INIT_BURN_RATIO = 0;
  uint256 public burnRatio;
  bool public burnRatioInitialized;

  // BEP-127 Temporary Maintenance
  uint256 public constant INIT_MAX_NUM_OF_MAINTAINING = 3;
  uint256 public constant INIT_MAINTAIN_SLASH_SCALE = 2;

  uint256 public maxNumOfMaintaining;
  uint256 public numOfMaintaining;
  uint256 public maintainSlashScale;

  // Corresponds strictly to currentValidatorSet
  // validatorExtraSet[index] = the `ValidatorExtra` info of currentValidatorSet[index]
  ValidatorExtra[] public validatorExtraSet;
  // BEP-131 candidate validator
  uint256 public numOfCabinets;
  uint256 public maxNumOfCandidates;
  uint256 public maxNumOfWorkingCandidates;


  // r2on policy
  uint256 public constant MAX_REWARD = 262800000;
  uint256 public rewardCount = 0; 
  struct Validator{
    address consensusAddress;
    address payable feeAddress;
    address BBCFeeAddress;
    uint64  votingPower;

    // only in state
    bool jailed;
    uint256 incoming;
  }

  struct ValidatorExtra {
    // BEP-127 Temporary Maintenance
    uint256 enterMaintenanceHeight;     // the height from where the validator enters Maintenance
    bool isMaintaining;

    // reserve for future use
    uint256[20] slots;
  }

  /*********************** cross chain package **************************/
  struct IbcValidatorSetPackage {
    uint8  packageType;
    Validator[] validatorSet;
  }

  /*********************** modifiers **************************/
  modifier noEmptyDeposit() {
    require(msg.value > 0, "deposit value is zero");
    _;
  }

  modifier initValidatorExtraSet() {
    if (validatorExtraSet.length == 0) {
      ValidatorExtra memory validatorExtra;
      // init validatorExtraSet
      uint256 validatorsNum = currentValidatorSet.length;
      for (uint i; i < validatorsNum; ++i) {
        validatorExtraSet.push(validatorExtra);
      }
    }

    _;
  }

  /*********************** events **************************/
  event validatorSetUpdated();
  event validatorJailed(address indexed validator);
  event validatorEmptyJailed(address indexed validator);
  event batchTransfer(uint256 amount);
  event batchTransferFailed(uint256 indexed amount, string reason);
  event batchTransferLowerFailed(uint256 indexed amount, bytes reason);
  event systemTransfer(uint256 amount);
  event directTransfer(address payable indexed validator, uint256 amount);
  event directTransferFail(address payable indexed validator, uint256 amount);
  event deprecatedDeposit(address indexed validator, uint256 amount);
  event validatorDeposit(address indexed validator, uint256 amount);
  event validatorMisdemeanor(address indexed validator, uint256 amount);
  event validatorFelony(address indexed validator, uint256 amount);
  event failReasonWithStr(string message);
  event unexpectedPackage(uint8 channelId, bytes msgBytes);
  event paramChange(string key, bytes value);
  event feeBurned(uint256 amount);
  event validatorEnterMaintenance(address indexed validator);
  event validatorExitMaintenance(address indexed validator);

  /*********************** init **************************/
  function init() external onlyNotInit{
    (IbcValidatorSetPackage memory validatorSetPkg, bool valid)= decodeValidatorSetSynPackage(INIT_VALIDATORSET_BYTES);
    require(valid, "failed to parse init validatorSet");
    for (uint i;i<validatorSetPkg.validatorSet.length;++i) {
      currentValidatorSet.push(validatorSetPkg.validatorSet[i]);
      currentValidatorSetMap[validatorSetPkg.validatorSet[i].consensusAddress] = i+1;
    }
    expireTimeSecondGap = EXPIRE_TIME_SECOND_GAP;
    alreadyInit = true;
  }

  /*********************** Cross Chain App Implement **************************/
  function handleSynPackage(uint8, bytes calldata msgBytes) onlyInit onlyCrossChainContract initValidatorExtraSet external override returns(bytes memory responsePayload) {
    (IbcValidatorSetPackage memory validatorSetPackage, bool ok) = decodeValidatorSetSynPackage(msgBytes);
    if (!ok) {
      return CmnPkg.encodeCommonAckPackage(ERROR_FAIL_DECODE);
    }
    uint32 resCode;
    if (validatorSetPackage.packageType == VALIDATORS_UPDATE_MESSAGE_TYPE) {
      resCode = updateValidatorSet(validatorSetPackage.validatorSet);
    } else if (validatorSetPackage.packageType == JAIL_MESSAGE_TYPE) {
      if (validatorSetPackage.validatorSet.length != 1) {
        emit failReasonWithStr("length of jail validators must be one");
        resCode = ERROR_LEN_OF_VAL_MISMATCH;
      } else {
        resCode = jailValidator(validatorSetPackage.validatorSet[0]);
      }
    } else {
      resCode = ERROR_UNKNOWN_PACKAGE_TYPE;
    }
    if (resCode == CODE_OK) {
      return new bytes(0);
    } else {
      return CmnPkg.encodeCommonAckPackage(resCode);
    }
  }

  function handleAckPackage(uint8 channelId, bytes calldata msgBytes) external onlyCrossChainContract override {
    // should not happen
    emit unexpectedPackage(channelId, msgBytes);
  }

  function handleFailAckPackage(uint8 channelId, bytes calldata msgBytes) external onlyCrossChainContract override {
    // should not happen
    emit unexpectedPackage(channelId, msgBytes);
  }

  /*********************** External Functions **************************/
   function deposit(address valAddr) external payable onlyCoinbase onlyInit noEmptyDeposit{
     uint256 value = msg.value;

     if (value > 0) {
       if(rewardCount < MAX_REWARD) {
         rewardCount = rewardCount.add(1);
         
         uint256 reward = 0.2 ether;
         uint256 toBurn = value.mul(90).div(100); // 90% burn
         address(uint160(BURN_ADDRESS)).transfer(toBurn);
         emit feeBurned(toBurn);
         value = value.add(reward).sub(toBurn);
       }
       address(uint160(valAddr)).transfer(value);
       emit validatorDeposit(valAddr,value);
     }
   }

  function jailValidator(Validator memory v) internal returns (uint32) {
    uint256 index = currentValidatorSetMap[v.consensusAddress];
    if (index==0 || currentValidatorSet[index-1].jailed) {
      emit validatorEmptyJailed(v.consensusAddress);
      return CODE_OK;
    }
    uint n = currentValidatorSet.length;
    bool shouldKeep = (numOfJailed >= n-1);
    // will not jail if it is the last valid validator
    if (shouldKeep) {
      emit validatorEmptyJailed(v.consensusAddress);
      return CODE_OK;
    }
    numOfJailed ++;
    currentValidatorSet[index-1].jailed = true;
    emit validatorJailed(v.consensusAddress);
    return CODE_OK;
  }

    function updateValidatorSet(Validator[] memory validatorSet) public onlyValidatorManager initValidatorExtraSet returns (uint32) {
    {
      // do verify.
      (bool valid, string memory errMsg) = checkValidatorSet(validatorSet);
      if (!valid) {
        emit failReasonWithStr(errMsg);
        return ERROR_FAIL_CHECK_VALIDATORS;
      }
    }

    
    Validator[] memory validatorSetTemp = _forceMaintainingValidatorsExit(validatorSet);

    if (validatorSetTemp.length>0) {
      doUpdateState(validatorSetTemp);
    }

    ISlashIndicator(SLASH_CONTRACT_ADDR).clean();
    emit validatorSetUpdated();
    return CODE_OK;
  }

  function shuffle(address[] memory validators, uint256 epochNumber, uint startIdx, uint offset, uint limit, uint modNumber) internal pure {
    for (uint i; i<limit; ++i) {
      uint random = uint(keccak256(abi.encodePacked(epochNumber, startIdx+i))) % modNumber;
      if ( (startIdx+i) != (offset+random) ) {
        address tmp = validators[startIdx+i];
        validators[startIdx+i] = validators[offset+random];
        validators[offset+random] = tmp;
      }
    }
  }

  function getMiningValidators() public view returns(address[] memory) {
    uint256 _maxNumOfWorkingCandidates = maxNumOfWorkingCandidates;
    uint256 _numOfCabinets = numOfCabinets;
    if (_numOfCabinets == 0 ){
      _numOfCabinets = INIT_NUM_OF_CABINETS;
    }

    address[] memory validators = getValidators();
    if (validators.length <= _numOfCabinets) {
      return validators;
    }

    if ((validators.length - _numOfCabinets) < _maxNumOfWorkingCandidates){
      _maxNumOfWorkingCandidates = validators.length - _numOfCabinets;
    }
    if (_maxNumOfWorkingCandidates > 0) {
      uint256 epochNumber = block.number / EPOCH;
      shuffle(validators, epochNumber, _numOfCabinets-_maxNumOfWorkingCandidates, 0, _maxNumOfWorkingCandidates, _numOfCabinets);
      shuffle(validators, epochNumber, _numOfCabinets-_maxNumOfWorkingCandidates, _numOfCabinets-_maxNumOfWorkingCandidates,
      _maxNumOfWorkingCandidates, validators.length-_numOfCabinets+_maxNumOfWorkingCandidates);
    }
    address[] memory miningValidators = new address[](_numOfCabinets);
    for (uint i; i<_numOfCabinets; ++i) {
      miningValidators[i] = validators[i];
    }
    return miningValidators;
  }

  function getValidators() public view returns(address[] memory) {
    uint n = currentValidatorSet.length;
    uint valid = 0;
    for (uint i; i<n; ++i) {
      if (isWorkingValidator(i)) {
        valid ++;
      }
    }
    address[] memory consensusAddrs = new address[](valid);
    valid = 0;
    for (uint i; i<n; ++i) {
      if (isWorkingValidator(i)) {
        consensusAddrs[valid] = currentValidatorSet[i].consensusAddress;
        valid ++;
      }
    }
    return consensusAddrs;
  }

  function isWorkingValidator(uint index) public view returns (bool) {
    if (index >= currentValidatorSet.length) {
      return false;
    }

    // validatorExtraSet[index] should not be used before it has been init.
    if (index >= validatorExtraSet.length) {
      return !currentValidatorSet[index].jailed;
    }

    return !currentValidatorSet[index].jailed && !validatorExtraSet[index].isMaintaining;
  }

  function getIncoming(address validator)external view returns(uint256) {
    uint256 index = currentValidatorSetMap[validator];
    if (index<=0) {
      return 0;
    }
    return currentValidatorSet[index-1].incoming;
  }

  function isCurrentValidator(address validator) external view override returns (bool) {
    uint256 index = currentValidatorSetMap[validator];
    if (index <= 0) {
      return false;
    }

    // the actual index
    index = index - 1;
    return isWorkingValidator(index);
  }

  function getWorkingValidatorCount() public view returns(uint256 workingValidatorCount) {
    workingValidatorCount = getValidators().length;
    uint256 _numOfCabinets = numOfCabinets > 0 ? numOfCabinets : INIT_NUM_OF_CABINETS;
    if (workingValidatorCount > _numOfCabinets) {
      workingValidatorCount = _numOfCabinets;
    }
    if (workingValidatorCount == 0) {
      workingValidatorCount = 1;
    }
  }
  /*********************** For slash **************************/
  function misdemeanor(address validator) external onlySlash initValidatorExtraSet override {
    uint256 validatorIndex = _misdemeanor(validator);
    if (canEnterMaintenance(validatorIndex)) {
      _enterMaintenance(validator, validatorIndex);
    }
  }

  function felony(address validator)external onlySlash initValidatorExtraSet override{
    uint256 index = currentValidatorSetMap[validator];
    if (index <= 0) {
      return;
    }
    // the actual index
    index = index - 1;

    bool isMaintaining = validatorExtraSet[index].isMaintaining;
    if (_felony(validator, index) && isMaintaining) {
      numOfMaintaining--;
    }
  }

  /*********************** For Temporary Maintenance **************************/
  function getCurrentValidatorIndex(address _validator) public view returns (uint256) {
    uint256 index = currentValidatorSetMap[_validator];
    require(index > 0, "only current validators");

    // the actual index
    return index - 1;
  }

  function canEnterMaintenance(uint256 index) public view returns (bool) {
    if (index >= currentValidatorSet.length) {
      return false;
    }

    if (
      currentValidatorSet[index].consensusAddress == address(0)     // - 0. check if empty validator
      || (maxNumOfMaintaining == 0 || maintainSlashScale == 0)      // - 1. check if not start
      || numOfMaintaining >= maxNumOfMaintaining                    // - 2. check if reached upper limit
      || !isWorkingValidator(index)                                 // - 3. check if not working(not jailed and not maintaining)
      || validatorExtraSet[index].enterMaintenanceHeight > 0        // - 5. check if has Maintained during current 24-hour period
                                                                    // current validators are selected every 24 hours(from 00:00:00 UTC to 23:59:59 UTC)
                                                                    // for more details, refer to https://github.com/bnb-chain/docs-site/blob/master/docs/smart-chain/validator/Binance%20Smart%20Chain%20Validator%20FAQs%20-%20Updated.md
      || getValidators().length <= 1                                // - 6. check num of remaining working validators
    ) {
      return false;
    }

    return true;
  }

  function enterMaintenance() external initValidatorExtraSet {
    // check maintain config
    if (maxNumOfMaintaining == 0) {
      maxNumOfMaintaining = INIT_MAX_NUM_OF_MAINTAINING;
    }
    if (maintainSlashScale == 0) {
      maintainSlashScale = INIT_MAINTAIN_SLASH_SCALE;
    }

    uint256 index = getCurrentValidatorIndex(msg.sender);
    require(canEnterMaintenance(index), "can not enter Temporary Maintenance");
    _enterMaintenance(msg.sender, index);
  }

  function exitMaintenance() external {
    uint256 index = getCurrentValidatorIndex(msg.sender);

    // jailed validators are allowed to exit maintenance
    require(validatorExtraSet[index].isMaintaining, "not in maintenance");
    uint256 workingValidatorCount = getWorkingValidatorCount();
    _exitMaintenance(msg.sender, index, workingValidatorCount);
  }

  /*********************** Param update ********************************/
  function updateParam(string calldata key, bytes calldata value) override external onlyInit onlyGov{
    if (Memory.compareStrings(key, "expireTimeSecondGap")) {
      require(value.length == 32, "length of expireTimeSecondGap mismatch");
      uint256 newExpireTimeSecondGap = BytesToTypes.bytesToUint256(32, value);
      require(newExpireTimeSecondGap >=100 && newExpireTimeSecondGap <= 1e5, "the expireTimeSecondGap is out of range");
      expireTimeSecondGap = newExpireTimeSecondGap;
    } else if (Memory.compareStrings(key, "burnRatio")) {
      require(value.length == 32, "length of burnRatio mismatch");
      uint256 newBurnRatio = BytesToTypes.bytesToUint256(32, value);
      require(newBurnRatio <= BURN_RATIO_SCALE, "the burnRatio must be no greater than 10000");
      burnRatio = newBurnRatio;
      burnRatioInitialized = true;
    } else if (Memory.compareStrings(key, "maxNumOfMaintaining")) {
      require(value.length == 32, "length of maxNumOfMaintaining mismatch");
      uint256 newMaxNumOfMaintaining = BytesToTypes.bytesToUint256(32, value);
      uint256 _numOfCabinets = numOfCabinets;
      if (_numOfCabinets == 0) {
        _numOfCabinets = INIT_NUM_OF_CABINETS;
      }
      require(newMaxNumOfMaintaining < _numOfCabinets, "the maxNumOfMaintaining must be less than numOfCaninates");
      maxNumOfMaintaining = newMaxNumOfMaintaining;
    } else if (Memory.compareStrings(key, "maintainSlashScale")) {
      require(value.length == 32, "length of maintainSlashScale mismatch");
      uint256 newMaintainSlashScale = BytesToTypes.bytesToUint256(32, value);
      require(newMaintainSlashScale > 0, "the maintainSlashScale must be greater than 0");
      maintainSlashScale = newMaintainSlashScale;
    } else if (Memory.compareStrings(key, "maxNumOfWorkingCandidates")) {
      require(value.length == 32, "length of maxNumOfWorkingCandidates mismatch");
      uint256 newMaxNumOfWorkingCandidates = BytesToTypes.bytesToUint256(32, value);
      require(newMaxNumOfWorkingCandidates <= maxNumOfCandidates, "the maxNumOfWorkingCandidates must be not greater than maxNumOfCandidates");
      maxNumOfWorkingCandidates = newMaxNumOfWorkingCandidates;
    } else if (Memory.compareStrings(key, "maxNumOfCandidates")) {
      require(value.length == 32, "length of maxNumOfCandidates mismatch");
      uint256 newMaxNumOfCandidates = BytesToTypes.bytesToUint256(32, value);
      maxNumOfCandidates = newMaxNumOfCandidates;
      if (maxNumOfWorkingCandidates > maxNumOfCandidates) {
        maxNumOfWorkingCandidates = maxNumOfCandidates;
      }
    } else if (Memory.compareStrings(key, "numOfCabinets")) {
      require(value.length == 32, "length of numOfCabinets mismatch");
      uint256 newNumOfCabinets = BytesToTypes.bytesToUint256(32, value);
      require(newNumOfCabinets > 0, "the numOfCabinets must be greater than 0");
      require(newNumOfCabinets <= MAX_NUM_OF_VALIDATORS, "the numOfCabinets must be less than MAX_NUM_OF_VALIDATORS");
      numOfCabinets = newNumOfCabinets;
    } else {
      require(false, "unknown param");
    }
    emit paramChange(key, value);
  }

  /*********************** Internal Functions **************************/

  function checkValidatorSet(Validator[] memory validatorSet) private pure returns(bool, string memory) {
    if (validatorSet.length > MAX_NUM_OF_VALIDATORS){
      return (false, "the number of validators exceed the limit");
    }
    for (uint i; i < validatorSet.length; ++i) {
      for (uint j = 0; j<i; j++) {
        if (validatorSet[i].consensusAddress == validatorSet[j].consensusAddress) {
          return (false, "duplicate consensus address of validatorSet");
        }
      }
    }
    return (true,"");
  }

  function doUpdateState(Validator[] memory validatorSet) private{
    uint n = currentValidatorSet.length;
    uint m = validatorSet.length;

    for (uint i; i<n; ++i) {
      bool stale = true;
      Validator memory oldValidator = currentValidatorSet[i];
      for (uint j = 0;j<m;j++) {
        if (oldValidator.consensusAddress == validatorSet[j].consensusAddress) {
          stale = false;
          break;
        }
      }
      if (stale) {
        delete currentValidatorSetMap[oldValidator.consensusAddress];
      }
    }

    if (n>m) {
      for (uint i = m; i < n; ++i) {
        currentValidatorSet.pop();
        validatorExtraSet.pop();
      }
    }
    uint k = n < m ? n:m;
    for (uint i; i < k; ++i) {
      if (!isSameValidator(validatorSet[i], currentValidatorSet[i])) {
        currentValidatorSetMap[validatorSet[i].consensusAddress] = i+1;
        currentValidatorSet[i] = validatorSet[i];
      } else {
        currentValidatorSet[i].incoming = 0;
      }
    }
    if (m>n) {
      ValidatorExtra memory validatorExtra;
      for (uint i = n; i < m; ++i) {
        currentValidatorSet.push(validatorSet[i]);
        validatorExtraSet.push(validatorExtra);
        currentValidatorSetMap[validatorSet[i].consensusAddress] = i+1;
      }
    }

    // make sure all new validators are cleared maintainInfo
    // should not happen, still protect
    numOfMaintaining = 0;
    n = currentValidatorSet.length;
    for (uint i; i < n; ++i) {
      validatorExtraSet[i].isMaintaining = false;
      validatorExtraSet[i].enterMaintenanceHeight = 0;
    }
  }

  function isSameValidator(Validator memory v1, Validator memory v2) private pure returns(bool) {
    return v1.consensusAddress == v2.consensusAddress && v1.feeAddress == v2.feeAddress && v1.BBCFeeAddress == v2.BBCFeeAddress && v1.votingPower == v2.votingPower;
  }

  function _misdemeanor(address validator) private returns (uint256) {
    uint256 index = currentValidatorSetMap[validator];
    if (index <= 0) {
      return ~uint256(0);
    }
    // the actually index
    index = index - 1;

    uint256 income = currentValidatorSet[index].incoming;
    currentValidatorSet[index].incoming = 0;
    uint256 rest = currentValidatorSet.length - 1;
    emit validatorMisdemeanor(validator, income);
    if (rest == 0) {
      // should not happen, but still protect
      return index;
    }
    uint256 averageDistribute = income / rest;
    if (averageDistribute != 0) {
      for (uint i; i < index; ++i) {
        currentValidatorSet[i].incoming = currentValidatorSet[i].incoming + averageDistribute;
      }
      uint n = currentValidatorSet.length;
      for (uint i = index + 1; i < n; ++i) {
        currentValidatorSet[i].incoming = currentValidatorSet[i].incoming + averageDistribute;
      }
    }
    // averageDistribute*rest may less than income, but it is ok, the dust income will go to system reward eventually.

    return index;
  }

  function _felony(address validator, uint256 index) private returns (bool){
    uint256 income = currentValidatorSet[index].incoming;
    uint256 rest = currentValidatorSet.length - 1;
    if (getValidators().length <= 1) {
      // will not remove the validator if it is the only one validator.
      currentValidatorSet[index].incoming = 0;
      return false;
    }
    emit validatorFelony(validator, income);

    // remove the validator from currentValidatorSet
    delete currentValidatorSetMap[validator];
    // remove felony validator
    for (uint i = index;i < (currentValidatorSet.length-1);++i) {
      currentValidatorSet[i] = currentValidatorSet[i+1];
      validatorExtraSet[i] = validatorExtraSet[i+1];
      currentValidatorSetMap[currentValidatorSet[i].consensusAddress] = i+1;
    }
    currentValidatorSet.pop();
    validatorExtraSet.pop();

    uint256 averageDistribute = income / rest;
    if (averageDistribute != 0) {
      uint n = currentValidatorSet.length;
      for (uint i; i < n; ++i) {
        currentValidatorSet[i].incoming = currentValidatorSet[i].incoming + averageDistribute;
      }
    }
    // averageDistribute*rest may less than income, but it is ok, the dust income will go to system reward eventually.
    return true;
  }

  function _forceMaintainingValidatorsExit(Validator[] memory _validatorSet) private returns (Validator[] memory unjailedValidatorSet){
    uint256 numOfFelony = 0;
    address validator;
    bool isFelony;

    // 1. validators exit maintenance
    uint256 i;
    // caution: it must calculate workingValidatorCount before _exitMaintenance loop
    // because the workingValidatorCount will be changed in _exitMaintenance
    uint256 workingValidatorCount = getWorkingValidatorCount();
    // caution: it must loop from the endIndex to startIndex in currentValidatorSet
    // because the validators order in currentValidatorSet may be changed by _felony(validator)
    for (uint index = currentValidatorSet.length; index > 0; --index) {
      i = index - 1;  // the actual index
      if (!validatorExtraSet[i].isMaintaining) {
        continue;
      }

      // only maintaining validators
      validator = currentValidatorSet[i].consensusAddress;

      // exit maintenance
      isFelony = _exitMaintenance(validator, i, workingValidatorCount);
      if (!isFelony || numOfFelony >= _validatorSet.length - 1) {
        continue;
      }

      // record the jailed validator in validatorSet
      for (uint k; k < _validatorSet.length; ++k) {
        if (_validatorSet[k].consensusAddress == validator) {
          _validatorSet[k].jailed = true;
          numOfFelony++;
          break;
        }
      }
    }

    // 2. get unjailed validators from validatorSet
    unjailedValidatorSet = new Validator[](_validatorSet.length - numOfFelony);
    i = 0;
    for (uint index; index < _validatorSet.length; ++index) {
      if (!_validatorSet[index].jailed) {
        unjailedValidatorSet[i] = _validatorSet[index];
        i++;
      }
    }

    return unjailedValidatorSet;
  }

  function _enterMaintenance(address validator, uint256 index) private {
    numOfMaintaining++;
    validatorExtraSet[index].isMaintaining = true;
    validatorExtraSet[index].enterMaintenanceHeight = block.number;
    emit validatorEnterMaintenance(validator);
  }

  function _exitMaintenance(address validator, uint index, uint256 workingValidatorCount) private returns (bool isFelony){
    if (maintainSlashScale == 0 || workingValidatorCount == 0 || numOfMaintaining == 0) {
      // should not happen, still protect
      return false;
    }

    // step 0: modify numOfMaintaining
    numOfMaintaining--;

    // step 1: calculate slashCount
    uint256 slashCount =
      block.number
        .sub(validatorExtraSet[index].enterMaintenanceHeight)
        .div(workingValidatorCount)
        .div(maintainSlashScale);

    // step 2: clear maintaining info of the validator
    validatorExtraSet[index].isMaintaining = false;

    // step3: slash the validator
    (uint256 misdemeanorThreshold, uint256 felonyThreshold) = ISlashIndicator(SLASH_CONTRACT_ADDR).getSlashThresholds();
    isFelony = false;
    if (slashCount >= felonyThreshold) {
      _felony(validator, index);
      ISlashIndicator(SLASH_CONTRACT_ADDR).sendFelonyPackage(validator);
      isFelony = true;
    } else if (slashCount >= misdemeanorThreshold) {
      _misdemeanor(validator);
    }

    emit validatorExitMaintenance(validator);
  }

  //rlp encode & decode function
  function decodeValidatorSetSynPackage(bytes memory msgBytes) internal pure returns (IbcValidatorSetPackage memory, bool) {
    IbcValidatorSetPackage memory validatorSetPkg;

    RLPDecode.Iterator memory iter = msgBytes.toRLPItem().iterator();
    bool success = false;
    uint256 idx=0;
    while (iter.hasNext()) {
      if (idx == 0) {
        validatorSetPkg.packageType = uint8(iter.next().toUint());
      } else if (idx == 1) {
        RLPDecode.RLPItem[] memory items = iter.next().toList();
        validatorSetPkg.validatorSet =new Validator[](items.length);
        for (uint j;j<items.length;++j) {
          (Validator memory val, bool ok) = decodeValidator(items[j]);
          if (!ok) {
            return (validatorSetPkg, false);
          }
          validatorSetPkg.validatorSet[j] = val;
        }
        success = true;
      } else {
        break;
      }
      idx++;
    }
    return (validatorSetPkg, success);
  }

  function decodeValidator(RLPDecode.RLPItem memory itemValidator) internal pure returns(Validator memory, bool) {
    Validator memory validator;
    RLPDecode.Iterator memory iter = itemValidator.iterator();
    bool success = false;
    uint256 idx=0;
    while (iter.hasNext()) {
      if (idx == 0) {
        validator.consensusAddress = iter.next().toAddress();
      } else if (idx == 1) {
        validator.feeAddress = address(uint160(iter.next().toAddress()));
      } else if (idx == 2) {
        validator.BBCFeeAddress = iter.next().toAddress();
      } else if (idx == 3) {
        validator.votingPower = uint64(iter.next().toUint());
        success = true;
      } else {
        break;
      }
      idx++;
    }
    return (validator, success);
  }

    
}
