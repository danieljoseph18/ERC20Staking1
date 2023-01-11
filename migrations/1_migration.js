const DanStakingToken = artifacts.require("DanStakingToken");

module.exports = function(deployer){
    deployer.deploy(DanStakingToken);
}