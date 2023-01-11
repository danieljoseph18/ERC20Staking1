const DanStakingToken = artifacts.require("DanStakingToken");

contract("DanStakingToken", async (accounts) => {

    let token;

    beforeEach(async () => {
        token = await DanStakingToken.deployed();
    });

    it("Should automatically transfer 10% of tokens to owner & 90% to contract", async () => {
        let ownerBalance = await token.balanceOf(accounts[0]);
        let contractBalance = await token.balanceOf(token.address);

        assert.equal(ownerBalance.toNumber(), 100000000000);
        assert.equal(contractBalance.toNumber(), 900000000000);
    });

    it("Should keep track of who has claimed their airdrop", async () => {
        await token.claimTokens({from: accounts[1]});
        let claimed = await token.hasClaimed(accounts[1]);
        assert.equal(claimed, true);
    });

    it("Should let users stake and unstake a specified amount of tokens", async () => {
        await token.stake(300, {from: accounts[1], gas:100000});
        let _stake = await token.amountStaked(accounts[1]);
        assert.equal(_stake.toNumber(), 300);
        await token.unstake(150, {from: accounts[1], gas:100000});
        _stake = await token.amountStaked(accounts[1]);
        assert.equal(_stake.toNumber(), 150);
    });

    it("Should let users unstake their entire stake, then stake it all again", async() => {
        await token.unstakeAll({from:accounts[1], gas:100000});
        let _stake = await token.amountStaked(accounts[1], {gas:100000});
        assert.equal(_stake.toNumber(), 0);
        let _balance = await token.balanceOf(accounts[1]);
        await token.stakeAll({from:accounts[1], gas:100000});
        _stake = await token.amountStaked(accounts[1], {gas:100000});
        assert.equal(_balance.toNumber(), _stake.toNumber());
    });

    it("Should let users withdraw the correct amount of earnings", async () => {
        let _balance = await token.balanceOf(accounts[1], {gas:100000});
        await new Promise(resolve => setTimeout(resolve,3000));
        await token.claimEarnings({from:accounts[1], gas:100000});
        let _newBalance = await token.balanceOf(accounts[1], {gas:100000});
        assert.notEqual(_balance.toNumber(), _newBalance.toNumber(), "Numbers are equal");
    });

    it("Should let users burn their tokens", async () => {
        await token.unstakeAll({from:accounts[1], gas:100000});
        let _balance = await token.balanceOf(accounts[1]);
        let _toBurn = 100000;
        await token.burn(_toBurn, {from:accounts[1], gas:100000});
        let _balAfterBurn = await token.balanceOf(accounts[1]);
        assert.equal(_balance - _toBurn, _balAfterBurn, "Incorrect no. of tokens burned");
        await token.burnAll({from:accounts[1], gas:100000});
        _balAfterBurn = await token.balanceOf(accounts[1]);
        assert.equal(_balAfterBurn, 0, "Not all tokens were burned");
    })







});