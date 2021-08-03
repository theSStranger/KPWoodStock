pragma solidity 0.5.3;

import './Exc.sol';
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import '../contracts/libraries/math/SafeMath.sol';

contract Pool {
    using SafeMath for uint;

    /// @notice some parameters for the pool to function correctly
    address private factory;
    address private tokenP;
    address private token1;
    address private dex;
    bytes32 private tokenPT;
    bytes32 private token1T;
    uint private callTime;
    // todo: create wallet data structures
    mapping(address => mapping(bytes32 => uint)) public balance;
    mapping(bytes32 => uint) public numToken;

    // todo: fill in the initialize method, which should simply set the parameters of the contract correctly. To be called once
    // upon deployment by the factory.
    function initialize(address _token0, address _token1, address _dex, uint whichP, bytes32 _tickerQ, bytes32 _tickerT)
    external {
        require(whichP == 1 || whichP == 2);
        require(callTime == 0);
        if (whichP == 1) {
            tokenP = _token0;
            token1 = _token1;
        } else {
            tokenP = _token1;
            token1 = _token0;
        }
        dex = _dex;
        tokenPT = _tickerQ;
        token1T = _tickerT;
        callTime.add(1);
    }

    // todo: implement wallet functionality and trading functionality
    function deposit(uint tokenAmount, uint pineAmount) external {
        IERC20(tokenP).transferFrom(msg.sender, address(this), pineAmount);
        IERC20(token1).transferFrom(msg.sender, address(this), tokenAmount);
        balance[msg.sender][tokenPT].add(pineAmount);
        balance[msg.sender][token1T].add(tokenAmount);
        numToken[tokenPT].add(pineAmount);
        numToken[token1T].add(tokenAmount);
        //How to find price?
        // Delete the last limited order before creating a new one
        // infer the price base on the token and the pine that the pool has
        //IExc(dex).makeLimitOrder(token1T, tokenAmount, numToken[token1T].div(numToken[tokenPT]), Side.SELL);
        //IExc(dex).makeLimitOrder(token1T, );
    }

    function withdraw(uint tokenAmount, uint pineAmount) external {
        require(balance[msg.sender][tokenPT] >= pineAmount);
        require(balance[msg.sender][token1T] >= tokenAmount);
        // if there is no more limit order, I should be able to withdraw
        IERC20(tokenP).transferFrom(address(this), msg.sender, pineAmount);
        IERC20(token1).transferFrom(address(this), msg.sender, tokenAmount);
        balance[msg.sender][tokenPT].sub(pineAmount);
        balance[msg.sender][token1T].sub(tokenAmount);
    }

    function testing(uint testMe) public view returns (uint) {
        if (testMe == 1) {
            return 5;
        } else {
            return 3;
        }
    }
}