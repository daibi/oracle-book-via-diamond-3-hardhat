const {
    getSelectors,
    FacetCutAction,
    removeSelectors,
    findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')

const { assert, expect } = require('chai')
const { ethers } = require('hardhat')

describe ('ItemFacetTest', async function() {
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let itemFacet
    let ownershipFacet
    let libERC721Factory
    let libERC3525Factory
    let libItem

    before(async function () {
      diamondAddress = await deployDiamond()
      libERC721Factory = await ethers.getContractFactory('LibERC721')
      libERC3525Factory = await ethers.getContractFactory('LibERC3525')
      libItem = await ethers.getContractFactory('LibItem')
      diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
      diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
      ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
      itemFacet = await ethers.getContractAt('ItemFacet', diamondAddress)
    })

    it('should successfully mint', async() => {
      // mint execution
      const [_, addr1] = await ethers.getSigners();
      await expect(itemFacet.mint(addr1.address, 1, 1))
        .to.emit(libERC3525Factory.attach(itemFacet.address), 'TransferValue').withArgs(ethers.constants.AddressZero, 1, 1);
    })
    
    it('should successfully transfer', async() => {
        // mint execution
      const [_, addr2] = await ethers.getSigners();
      await expect(itemFacet.mint(addr2.address, 1, 0))
        .to.emit(libERC3525Factory.attach(itemFacet.address), 'TransferValue').withArgs(ethers.constants.AddressZero, 2, 0);
      await expect(itemFacet.transferFrom(1, 2, 1))
        .to.emit(libERC3525Factory.attach(itemFacet.address), 'TransferValue').withArgs(1, 2, 1);
      })

})