pragma solidity 0.5.3;
pragma experimental ABIEncoderV2;

/// @notice these commented segments will differ based on where you're deploying these contracts. If you're deploying
/// on remix, feel free to uncomment the github imports, otherwise, use the uncommented imports

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/token/ERC20/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import '../contracts/libraries/token/ERC20/ERC20.sol';
import '../contracts/libraries/math/SafeMath.sol';
import "./IExc.sol";

contract Exc is IExc{
    /// @notice simply notes that we are using SafeMath for uint, since Solidity's math is unsafe. For all the math
    /// you do, you must use the methods specified in SafeMath (found at the github link above), instead of Solidity's
    /// built-in operators.
    using SafeMath for uint;
    
    /// @notice these declarations are incomplete. You will still need a way to store the orderbook, the balances
    /// of the traders, and the IDs of the next trades and orders. Reference the NewTrade event and the IExc
    /// interface for more details about orders and sides.
    mapping(bytes32 => Token) public tokens;
    bytes32[] public tokenList;
    address private factory;
    bytes32 constant PIN = bytes32('PIN');
    // orderBook store the record of how to refer to the order
    mapping(bytes32 => mapping(uint => Order[])) public orderBook;
    mapping(address => mapping(bytes32 => uint)) public traderBalances;
    uint public nextOrderID;
    uint public nextTraderID;

    /// @notice an event representing all the needed info regarding a new trade on the exchange
    event NewTrade(
        uint tradeId,
        uint orderId,
        bytes32 indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint amount,
        uint price,
        uint date
    );
    
    // todo: implement getOrders, which simply returns the orders for a specific token on a specific side
    function getOrders(
      bytes32 ticker, 
      Side side) 
      external 
      view
      returns(Order[] memory) {
        return orderBook[ticker][uint(side)];
    }

    // todo: implement getTokens, which simply returns an array of the tokens currently traded on in the exchange
    function getTokens() 
      external 
      view 
      returns(Token[] memory) {
        Token[] memory out = new Token[](tokenList.length);
        for (uint i = 0; i < tokenList.length; i ++) {
            out[i] = tokens[tokenList[i]];
        }
        return out;
    }
    
    // todo: implement addToken, which should add the token desired to the exchange by interacting with tokenList and tokens
    function addToken(
        bytes32 ticker,
        address tokenAddress)
        external {
        tokenList.push(ticker);
        tokens[ticker] = Token(ticker, tokenAddress);
    }
    
    // todo: implement deposit, which should deposit a certain amount of tokens from a trader to their on-exchange wallet,
    // based on the wallet data structure you create and the IERC20 interface methods. Namely, you should transfer
    // tokens from the account of the trader on that token to this smart contract, and credit them appropriately
    function deposit(
        uint amount,
        bytes32 ticker)
        external {
        // This could be an error
        //require(tokenExists(ticker));
        IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].add(amount);
    }
    
    // todo: implement withdraw, which should do the opposite of deposit. The trader should not be able to withdraw more than
    // they have in the exchange.
    function withdraw(
        uint amount,
        bytes32 ticker)
        external {
        //require(tokenExists(ticker));
        require(traderBalances[msg.sender][ticker] >= amount);

        IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, amount);
        traderBalances[msg.sender][ticker] = traderBalances[msg.sender][ticker].sub(amount);
    }
    
    // todo: implement makeLimitOrder, which creates a limit order based on the parameters provided. This method should only be
    // used when the token desired exists and is not pine. This method should not execute if the trader's token or pine balances
    // are too low, depending on side. This order should be saved in the orderBook
    
    // todo: implement a sorting algorithm for limit orders, based on best prices for market orders having the highest priority.
    // i.e., a limit buy order with a high price should have a higher priority in the orderbook.
    function makeLimitOrder(
        bytes32 ticker,
        uint amount,
        uint price,
        Side side)
        external {
        require(traderBalances[msg.sender][ticker] >= amount);
        Order memory out = Order(nextOrderID, msg.sender, side, ticker, amount, 0, price, now);
        orderBook[ticker][uint(side)].push(out);
        if (side == Side.BUY) {
            //sort highest price as the most priority
            for (uint i = orderBook[ticker][uint(side)].length - 1; i > 0; i --) {
                if (orderBook[ticker][uint(side)][i].price > orderBook[ticker][uint(side)][i - 1].price) {
                    Order memory swapper = orderBook[ticker][uint(side)][i];
                    orderBook[ticker][uint(side)][i] = orderBook[ticker][uint(side)][i - 1];
                    orderBook[ticker][uint(side)][i - 1] = swapper;
                }
            }
        } else {
            //sort reverse for the first one
            for (uint i = orderBook[ticker][uint(side)].length - 1; i > 0; i --) {
                if (orderBook[ticker][uint(side)][i].price < orderBook[ticker][uint(side)][i - 1].price) {
                    Order memory swapper = orderBook[ticker][uint(side)][i];
                    orderBook[ticker][uint(side)][i] = orderBook[ticker][uint(side)][i - 1];
                    orderBook[ticker][uint(side)][i - 1] = swapper;
                }
            }
        }
        nextOrderID += 1;
    }
    
    // todo: implement deleteLimitOrder, which will delete a limit order from the orderBook as long as the same trader is deleting
    // it.

        function deleteLimitOrder(
        uint id,
        bytes32 ticker,
        Side side) external returns (bool) {
            if (orderBook[ticker][uint(side)].length == 0) {
                return false;
            } else {
                for (uint i = 0; i < orderBook[ticker][uint(side)].length; i ++) {
                    if (orderBook[ticker][uint(side)][i].id == id && orderBook[ticker][uint(side)][i].trader == msg.sender) {
                        for (uint j = i; j < orderBook[ticker][uint(side)].length-1; j++){
                            orderBook[ticker][uint(side)][j] = orderBook[ticker][uint(side)][j+1];
                        }
                        delete orderBook[ticker][uint(side)][orderBook[ticker][uint(side)].length-1];
                        orderBook[ticker][uint(side)].length--;
                    }
                }
                return false;
            }
    }
    
    // todo: implement makeMarketOrder, which will execute a market order on the current orderbook. The market order need not be
    // added to the book explicitly, since it should execute against a limit order immediately. Make sure you are getting rid of
    // completely filled limit orders!
    function makeMarketOrder(
        bytes32 ticker,
        uint amount,
        Side side)
        external {
        uint iamount = amount;
        uint iterator = 0;
        if (side == Side.BUY) {

            while (iamount > 0) {
                if (iterator >= orderBook[ticker][uint(Side.SELL)].length) {
                    return;
                }
                if (orderBook[ticker][uint(Side.SELL)][iterator].filled.add(iamount) <= orderBook[ticker][uint(Side.SELL)][iterator].amount) {
                    orderBook[ticker][uint(Side.SELL)][iterator].filled = orderBook[ticker][uint(Side.SELL)][iterator].filled.add(iamount);
                    if (orderBook[ticker][uint(Side.SELL)][iterator].filled == orderBook[ticker][uint(Side.SELL)][iterator].amount) {
                        IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, orderBook[ticker][uint(Side.SELL)][iterator].trader, iamount);
                        delete orderBook[ticker][uint(Side.SELL)][iterator];
                    }
                    return;
                } else {
                    iamount = iamount.sub(orderBook[ticker][uint(Side.SELL)][iterator].amount).add(orderBook[ticker][uint(Side.SELL)][iterator].filled);
                    IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, orderBook[ticker][uint(Side.SELL)][iterator].trader,
                        orderBook[ticker][uint(Side.SELL)][iterator].amount.sub(orderBook[ticker][uint(Side.SELL)][iterator].filled));
                    delete orderBook[ticker][uint(Side.SELL)][iterator];
                }
                iterator++;
            }
        } else {
            while (iamount > 0) {
                if (iterator >= orderBook[ticker][uint(Side.BUY)].length) {
                    return;
                }
                if (orderBook[ticker][uint(Side.BUY)][iterator].filled.add(iamount) <= orderBook[ticker][uint(Side.BUY)][iterator].amount) {
                    orderBook[ticker][uint(Side.BUY)][iterator].filled = orderBook[ticker][uint(Side.BUY)][iterator].filled.add(iamount);
                    if (orderBook[ticker][uint(Side.BUY)][iterator].filled == orderBook[ticker][uint(Side.BUY)][iterator].amount) {
                        IERC20(tokens[ticker].tokenAddress).transferFrom(orderBook[ticker][uint(Side.SELL)][iterator].trader, msg.sender, iamount);
                        delete orderBook[ticker][uint(Side.BUY)][iterator];
                    }
                    return;
                } else {
                    iamount = iamount.sub(orderBook[ticker][uint(Side.BUY)][iterator].amount).add(orderBook[ticker][uint(Side.BUY)][iterator].filled);
                    IERC20(tokens[ticker].tokenAddress).transferFrom(orderBook[ticker][uint(Side.SELL)][iterator].trader, msg.sender,
                        orderBook[ticker][uint(Side.SELL)][iterator].amount.sub(orderBook[ticker][uint(Side.SELL)][iterator].filled));
                    delete orderBook[ticker][uint(Side.BUY)][iterator];
                }
                iterator++;
            }
        }
    }
    
    //todo: add modifiers for methods as detailed in handout
    modifier tokenExists(bytes32 ticker) {
        require(tokens[ticker].tokenAddress != address(0));
        _;
    }

    function get_balance_trader_n_coin(address trader, bytes32 coin){
        return traderBalances[trader][coin];
    }

}