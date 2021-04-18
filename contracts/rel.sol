pragma solidity =0.5.16;

library FactoryLibrary{
    function pairFor(address factory, address token,uint256 id) internal pure returns (address pair) {
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token,id)),
                //0x0afa02c44aeb581b450b6a51600f4042ed508222ac645cef10092896a104dfb8
                hex'0a3f50a45bf91a086376ab52e44bc5dcb80a9aa9ae9e31ccbf0534132f8d0ab9' // init code hash
            ))));
    }
}

interface liquidityAmountInter{
    function getSwapAmountOut(uint amIn,address token0,address token1) external view returns(uint256 amountOut);
}

contract trustRel{
    
    address public Owner;
    address public factoryAddr;
    address public liqAmountAddr;

    uint256 public PID;
    mapping(address => uint256) public plyID;
    struct parent{
        uint256 id;
        address parentAddr;
    }
    mapping(address => parent) public plyRel;
    
    mapping(address => uint256) public pidLimit;// this is differnt limit in 
    address public WETH = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    //address public USDT = address(0x7D7574cF25A061c2a98444a49C544c4c5C3Cad6A);
    address public USDT = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    
    constructor(address _factory) public{
        factoryAddr = _factory;
        Owner = msg.sender;
        PID = 0;
        pidLimit[WETH] = 2*1e18;
        pidLimit[USDT] = 500*1e18;
    }
    
    function getCoinPrice(uint256 inAmount,address _tokenA,address _tokenB) public view returns(uint256){
        //return liquidityAmountInter(liqAmountAddr).getSwapAmountOut(inAmount,_tokenA,_tokenB);
        return 500*1e18;
    }
    
    function updateReciverCoin(address _coin,uint256 _limit) public {
        require(msg.sender != factoryAddr,"only factory");
        pidLimit[_coin] = _limit;
    }
    
    function getCoinLimit(address _coin) view public returns(uint256){
        return pidLimit[_coin];
    }
    function getPlyPid(address _ply) view public returns(uint256){
        return plyID[_ply]; 
    }
    
    function getParent(address _ply) view public returns(uint256 _id,address _parent){
        _id = plyRel[_ply].id;
        _parent = plyRel[_ply].parentAddr;
    }
    
    function createID(address _token,address _ply,uint256 id) public  onlyPair(msg.sender,_token,id){
        require(plyID[_ply] == 0,"trustRel pid already exit");
        PID++;
        plyID[_ply] = PID;
    }
    
    function regParent(address _token,address _ply,address _parent,uint256 id) public onlyPair(msg.sender,_token,id){
        uint256 parentID = plyID[_parent];
        require(parentID >0,"parent not exit");
        require(plyRel[_ply].id == 0,"already have parent");
        parent storage p = plyRel[_ply];
        
        p.id = parentID;
        p.parentAddr = _parent;
    }
    
    modifier onlyPair(address sender,address _token,uint256 id){
        require(FactoryLibrary.pairFor(factoryAddr,_token,id) == sender,"not right sender");
        _;
    }
    
    function getPair(address _token,uint256 id) public view returns(address){
        return FactoryLibrary.pairFor(factoryAddr,_token,id);
    }
    
    
}