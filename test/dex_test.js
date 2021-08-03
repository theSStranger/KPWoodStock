const { expectRevert } = require('@openzeppelin/test-helpers');
const Pin = artifacts.require('dummy/Pin.sol');
const Zrx = artifacts.require('dummy/Zrx.sol');
const Exc = artifacts.require('Exc.sol');

const SIDE = {
    BUY: 0,
    SELL: 1
};

contract('Exc', (accounts) => {
    let pin, zrx, exc;
    const [trader1, trader2] = [accounts[1], accounts[2]];
    const [PIN, ZRX] = ['PIN', 'ZRX']
        .map(ticker => web3.utils.fromAscii(ticker));

    beforeEach(async() => {
        ([pin, zrx] = await Promise.all([
            Pin.new(),
            Zrx.new()
        ]));
        exc = await Exc.new();
        await exc.addToken(PIN, pin.address);
        await exc.addToken(ZRX, zrx.address);

        await pin.mint(trader1, web3.utils.toWei('200'));
        await zrx.mint(trader1, web3.utils.toWei('200'));
    });

    it('test depositing', async () => {
        await zrx.approve(exc.address, web3.utils.toWei('5'), {from: trader1});
        await exc.deposit(web3.utils.toWei('5'), ZRX, {from: trader1})
        // write a get_trader_balance function to Exc.sol pass in the trader and type of coin
        assert(exc.get_balance_trader_n_coin(trader1, ZRX), web3.utils.toWei('5'));
    });

    it('test withdrawing', async () => {
        await zrx.approve(exc.address, web3.utils.toWei('5'), {from: trader1});
        await exc.deposit(web3.utils.toWei('5'), ZRX, {from: trader1})
        assert(exc.get_balance_trader_n_coin(trader1, ZRX), web3.utils.toWei('5'));
        await exc.withdraw(web3.utils.toWei('5'), ZRX, {from: trader1});
        asser(exc.get_balance_trader_n_coin(trader1, ZRX), web3.utils.toWei('0'));
    });

    it('deleting limit order fir ZRX', async () => {
        await zrx.approve(exc.address, web3.utils.toWei('5'), {from: trader1});
        await exc.deposit(web3.utils.toWei('5'), ZRX, SIDE.SELL {from: trader1})
        assert(exc.get_balance_trader_n_coin(trader1, ZRX), web3.utils.toWei('5'));

        await exc.makeLimitOrder(ZRX, web3.utils.toWie('5'), {from: trader1});
        assert(exc.get_balance_trader_n_coin(trader1, ZRX), web3.utils.toWei('0'));
        await exc.deleteLimitOrder(1, ZRX, SIDE.SELL, {from : trader1})
        assert(exc.get_balance_trader_n_coin(trader1, ZRX), web3.utils.toWei('5'))
    });


    it('deleting limit order for PIN', async () => {
        await pin.approve(exc.address, web3.utils.toWei('5'), {from: trader1});
        await exc.deposit(web3.utils.toWei('5'), PIN, SIDE.SELL, {from: trader1})
        assert(exc.get_balance_trader_n_coin(trader1, PIN), web3.utils.toWei('5'));

        await exc.makeLimitOrder(PIN, web3.utils.toWie('5'), {from: trader1});
        assert(exc.get_balance_trader_n_coin(trader1, PIN), web3.utils.toWei('0'));
        await exc.deleteLimitOrder(1, PIN, SIDE.SELL, {from : trader1})
        assert(exc.get_balance(trader1, PIN), web3.utils.toWei('5'))
    });


    it('making limit order', async () => {
        //BEFORE DEPOSIT APPROVE
        await zrx.approve(exc.address, web3.utils.toWei('5'), {from: trader1});
        await exc.deposit(web3.utils.toWei('5'), ZRX, SIDE.SELL, {from: trader1})
        assert(exc.get_balance_trader_n_coin(trader1, ZRX), web3.utils.toWei('5'));

        await exc.makeLimitOrder(ZRX, web3.utils.toWie('5'), {from: trader1});
        assert(exc.get_balance_trader_n_coin(trader1, ZRX), web3.utils.toWei('0'));
        await exc.deleteLimitOrder(1, ZRX, SIDE.SELL, {from : trader1})
        assert(exc.get_balance_trader_n_coin(trader1, ZRX), web3.utils.toWei('5'))
    });
});