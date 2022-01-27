var LoudNft = artifacts.require("LoudNft");

module.exports = function(deployer) {
  deployer.deploy(LoudNft, 'LoudNFT Collectible', 'LOUDNFT', '');
};