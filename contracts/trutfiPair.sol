pragma solidity =0.5.16;

interface IERC20 {
    function decimals() external view returns(uint8);
    function symbol() external view returns(string memory);
        //string public constant name = "test USDT";

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external ;
    function mint(address account, uint amount) external;

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external ;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface relInter{
    function getPlyPid(address _ply) view external returns(uint256) ;
    function getParent(address _ply) view external returns(uint256 _id,address _parent);
    function updateReciverCoin(address _coin,uint256 _limit) external;
    function getCoinLimit(address _coin) view external returns(uint256);
    function createID(address _token,address _ply,uint256 _id) external;
    //function getCoinPrice(uint256 inAmount,address _tokenA,address _tokenB) external view returns(uint256);
    function regParent(address _token,address _ply,address _parent,uint256 _id) external;
}


library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}

interface ItrustPair{
    function initialize(address _relAddr,
                        address _feeTo,
                        address _creater,
                        address _Sale,
                        address _Receiver,
                        uint256 _rate,
                        uint256 _saleAmount,
                        uint256 _topLimit,
                        uint256 _endTime) external;
    function initialize2(uint256 _id,string calldata _name,address _feeTo2) external;
    
}
contract trustPair is ItrustPair{
    
    using SafeMath for *;
    
    address public relAddr;
    address public factory;
    address public creater;
    address public feeTo;
    address public feeTo2;
    address public tokenSale; // token A 
    address public tokenReceive; // token B 
    string  public name;
    uint256 public rate; // 1 receive = n sale 
    uint256 public saleAmount;
    uint256 public receiveAmount;
    uint256 public airdropAmount;
    uint256 public topLimit; // this receive amount;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public id;
    
    uint256 public recDecimals;
    
    uint256 public totalReceive;
    uint256 public totalSale;
    uint256 public totalAir;
    
    mapping(address => uint256) public plyBuy;
    
    //address public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    //address public USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public constant WETH = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    //address public USDT = address(0x7D7574cF25A061c2a98444a49C544c4c5C3Cad6A);
    address public constant USDT = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant TRANSFERRROM = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    
    constructor() public{
        factory = msg.sender;
    }
    
    function initialize(address _relAddr,
                        address _feeTo,
                        address _creater,
                        address _Sale,
                        address _Receiver,
                        uint256 _rate,
                        uint256 _saleAmount,
                        uint256 _topLimit,
                        uint256 _endTime) external {
        require(msg.sender == factory,"only factory");                    
        require(_endTime > now,"already end");
        require(_rate >0,"rate need big then 0");

        relAddr = _relAddr;
        feeTo = _feeTo;
        creater = _creater;
        tokenSale = _Sale;
        tokenReceive = _Receiver;
        rate = _rate;
        saleAmount = _saleAmount;
        topLimit = _topLimit;
        startTime = now;
        endTime = _endTime;
        airdropAmount = _saleAmount.mul(1).div(100);
        recDecimals = IERC20(_Sale).decimals();
        //receiveAmount = _saleAmount.mul(rate).div(10**recDecimals);
        //IERC20(tokenSale).transferFrom(creater,address(this),saleAmount.add(airdropAmount));
        _safeTransferFrom(tokenSale,creater,address(this),saleAmount.add(airdropAmount));
        
    }
    
    function initialize2(uint256 _id,string calldata _name,address _feeTo2) external { 
        require(msg.sender == factory,"only factory");
        id = _id;
        name = _name;
        receiveAmount = saleAmount.div(rate);
        feeTo2 = _feeTo2;
    }
    
    function getPairInfo() public view returns(string memory _SaleName,
                                                string memory _ReceivereName_,
                                                string memory _poolName,
                                                uint256 _rate,
                                                uint256 _receiverAmount,
                                                uint256 _toteReceive,
                                                uint256 _topLimit,
                                                uint256 _endTime,
                                                uint256 state){
        _SaleName = IERC20(tokenSale).symbol();
        _ReceivereName_ = IERC20(tokenReceive).symbol();
        _rate = rate ;
        _receiverAmount = receiveAmount;
        _toteReceive = totalReceive;
        _topLimit = topLimit;
        _endTime = endTime;
        _poolName = name;
        if(now >= endTime){
            if(totalReceive == receiveAmount){
                state = 4; //  end
            }else{
                state = 3; // fail 
            }
        }else{
            if(totalReceive == receiveAmount){
                state = 2; //  success
            }else{
                state = 1; // pending 
            }
        }
                                                        
    }
    
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }
    
    function _safeTransferFrom(address token, address _from, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFERRROM, _from,to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FROM_FAILED');
    }
    
    function exchange(uint256 _amount,address _parent) public payable{
        require(now <= endTime,"already end");
        require(saleAmount > totalSale,"already get all");
        uint256 pid = relInter(relAddr).getPlyPid(msg.sender);
        require(plyBuy[msg.sender] == 0,"already buy");
        uint256 amount;
        if(tokenReceive == WETH){
            //eth
            require(_amount = msg.value, "trutfiPair: msg.value is not equals to _amount");
            amount = msg.value;
        }else{
            // usdt or other coin
            amount = _amount;
        }
        require(amount >0 ,"not enght ");
        if(topLimit > 0){
            require(amount <=topLimit  ,"up to topLimit");
        }
    
        createID(pid,msg.sender,amount);
        address parentAddr  = updateParent(msg.sender,_parent);
        uint256 leftBuyAmount;
        uint256 buyAmount;
        uint256 fee;
        uint256 parentAmount;
        
        
        buyAmount = amount.mul(rate);

        if(saleAmount < totalSale + buyAmount ){
            uint256 canBuy = saleAmount.sub(totalSale);
            leftBuyAmount = amount.sub(canBuy.div(rate));
            buyAmount = canBuy;
            amount = amount.sub(leftBuyAmount);
            if(tokenReceive == WETH){
                msg.sender.transfer(leftBuyAmount);
            }else{
                _safeTransfer(tokenReceive,msg.sender,leftBuyAmount);
            }
        }

        totalSale = totalSale.add(buyAmount);
        totalReceive  = totalReceive.add(amount);
        
        fee = amount.mul(1).div(100);
        uint256 fee2 = fee.mul(3).div(100);
        uint256 leftAmount = amount.sub(fee);
        
        if(parentAddr != address(0)){
            parentAmount = buyAmount.mul(1).div(100);
            totalAir = totalAir.add(parentAmount);
            if(parentAmount > 0){
                _safeTransfer(tokenSale,parentAddr,parentAmount);
            }
        }
        plyBuy[msg.sender] = plyBuy[msg.sender].add(buyAmount);
        _safeTransfer(tokenSale,msg.sender,buyAmount);
        
        if(tokenReceive == WETH){
            toPayable(creater).transfer(leftAmount);
            
            toPayable(feeTo).transfer(fee.sub(fee2));
            toPayable(feeTo2).transfer(fee2);
        }else{
            _safeTransferFrom(tokenReceive,msg.sender,creater,leftAmount);
            _safeTransferFrom(tokenReceive,msg.sender,feeTo,fee.sub(fee2));
            _safeTransferFrom(tokenReceive,msg.sender,feeTo2,fee2);
        }
        
        
        
    }

    
    function cleamAir() public{
        require(msg.sender == feeTo,"not fee to addr");
        require(now >= endTime,"not end");
        require(airdropAmount > totalAir,"not enght airdrop token");
        
        uint256 canCleam = airdropAmount.sub(totalAir);
        totalAir  = airdropAmount;

        _safeTransfer(tokenSale,feeTo,canCleam);
    }
    
    function cleamLeftAmount() public{
        require(msg.sender == creater,"only creater");
        require(now >= endTime,"not end");
        require(saleAmount > totalSale,"already success");
        uint256 canCleam = saleAmount.sub(totalSale);
        totalSale = saleAmount;
        _safeTransfer(tokenSale,creater,canCleam);
    }
    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function createID(uint256 _pid,address _ply,uint256 _amount) internal{
        if(_pid >0){
            return;
        }
        uint256 limit = relInter(relAddr).getCoinLimit(tokenReceive);
        if(_amount >= limit){
            relInter(relAddr).createID(tokenSale,_ply,id);
        }
        /*
        uint256 limit = relInter(relAddr).getCoinLimit(USDT);
        if(tokenReceive == USDT){
            if(_amount >= limit){
                relInter(relAddr).createID(tokenSale,_ply,id);
            }
        }else{
            // getValue
            uint256 value = relInter(relAddr).getCoinPrice(limit,USDT,tokenReceive);
            if(_amount > value){
                relInter(relAddr).createID(tokenSale,_ply,id);
            }
        }*/
    }
    
    function updateParent(address _ply,address _parent) internal  returns(address _parentAddr){
        require(_ply != _parent,"ply can not equals to parent");
        (uint256 parentid,address parentAddr) = relInter(relAddr).getParent(_ply);
        if(parentid == 0){
            uint256 pid = relInter(relAddr).getPlyPid(_parent);
            if(pid > 0){
                // need update _ply parent
               relInter(relAddr).regParent(tokenSale,_ply,_parent,id);
               _parentAddr = _parent; 
               return _parentAddr;
            }
        }else{
            if(_parent != parentAddr){
                _parentAddr = parentAddr;
                return _parentAddr;
            }
        }
        _parentAddr = address(0);
        
    }
    
    
}

contract trustFacotry{
    address  public feeTo;
    address public feeTo2;
    address public feeSetter;
    
    address public relAddr;
    
    //mapping(address => address) public token_pair;
    mapping(address => string) public token_name;
    address[] public pairList;
    uint256 public pairID;
    mapping(uint256 => address) public pid_pair;
    mapping(string => address[]) public name_pairList;
    mapping(address => address[]) public creater_pairList;
    mapping(address => address[]) public token_pairList;
    mapping(address => uint256) public pair_pid;
    
    event AuctionCreated(address _sale, string  _name, address pair, uint length);
    
    constructor(address _feeTo,address _feeTo2) public{
        require(_feeTo != address(0), "_feeTo zero address");
        require(_feeTo2 != address(0), "_feeTo2 zero address");
        feeTo = _feeTo;
        feeTo2 = _feeTo2;
        feeSetter = msg.sender;
    }
    
    function setRelAddr(address _relAddr) public{
        require(msg.sender == feeSetter,"only feeSetter");
        require(_relAddr != address(0), "_relAddr zero address");
         relAddr = _relAddr;
    }

    function createAuction(
                        string memory  _name,
                        address _Sale,
                        address _Receiver,
                        uint256 _rate,
                        uint256 _saleAmount,
                        uint256 _topLimit,
                        uint256 _endTime) public {
                            
        //require(token_pair[_Sale] != address(0), 'already create auction');
        require(relAddr != address(0),"not set rel Addr");
        pairID++;
        require(_Sale != address(0), ' ZERO_ADDRESS');
        
        bytes memory bytecode = type(trustPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_Sale,pairID));
        address pair;
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        string memory nameLower = _toLower(_name);

        pid_pair[pairID] = pair;
        pair_pid[pair] = pairID;
        name_pairList[nameLower].push(pair);
        creater_pairList[msg.sender].push(pair);
        token_pairList[_Sale].push(pair);
        
        
        ItrustPair(pair).initialize(relAddr, feeTo,msg.sender,_Sale,_Receiver,_rate,_saleAmount,_topLimit,_endTime);
        ItrustPair(pair).initialize2(pairID,_name,feeTo2);
        pairList.push(pair);
        emit AuctionCreated(_Sale,_name, pair, pairList.length);
        token_name[_Sale] = _name;
    }
    
    function setFeeOne(address _feeTo) public{
        require(msg.sender == feeSetter,"only feeSetter");
        require(_feeTo != address(0), "_feeTo zero address");
        feeTo = _feeTo;
    }
    function setFeeTwo(address _feeTo2) public{
        require(msg.sender == feeSetter,"only feeSetter");
        require(_feeTo2 != address(0), "_feeTo2 zero address");
        feeTo2 = _feeTo2;
    }
    function getPairByID(uint256 _pID) public view returns(address){
        return pid_pair[_pID];
    }
    
    function getPairByName(string memory _name) public view returns(address[] memory _pairList,uint256[] memory _idList){
        string memory nameLower = _toLower(_name);
        uint256 len = name_pairList[nameLower].length;
        
        if(len > 0){
            _pairList = new address[](len);
            _idList = new uint256[](len);
            
            for(uint256 i=0;i<len;i++){
                _pairList[i] = name_pairList[nameLower][i];
                _idList[i] = pair_pid[_pairList[i]];
            }
        }
    }
    
    function getPairByCreator(address _creater) public view returns(address[] memory _pairList,uint256[] memory _idList){
        uint256 len = creater_pairList[_creater].length;
        
        if(len > 0){
            _pairList = new address[](len);
            _idList = new uint256[](len);
            
            for(uint256 i=0;i<len;i++){
                _pairList[i] = creater_pairList[_creater][i];
                _idList[i] = pair_pid[_pairList[i]];
            }
        }
    }
    function getPairByCoin(address _coin) public view returns(address[] memory _pairList,uint256[] memory _idList){
        uint256 len = token_pairList[_coin].length;
        
        if(len > 0){
            _pairList = new address[](len);
            _idList = new uint256[](len);
            
            for(uint256 i=0;i<len;i++){
                _pairList[i] = token_pairList[_coin][i];
                _idList[i] = pair_pid[_pairList[i]];
            }
        }
    }
    function _toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    function getHash() public pure returns(bytes32  hash_pair) {
        hash_pair  = keccak256(type(trustPair).creationCode);
    }
    
    function setCreateLinkLimit(address _token,uint256 _limit) public{
        require(msg.sender == feeSetter,"only feeSetter");
        require(relAddr != address(0),"not set relAddr");
        relInter(relAddr).updateReciverCoin(_token,_limit);
    }
}
