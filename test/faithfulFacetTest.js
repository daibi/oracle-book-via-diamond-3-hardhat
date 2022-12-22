const {
    getSelectors,
    FacetCutAction,
    removeSelectors,
    findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')

const { assert, expect } = require('chai')
const { ethers } = require('hardhat')

describe ('FaithfulFacetTest', async function() {
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let faithfulFacet
    let vrfFacet
    let ownershipFacet
    let mockVRFCoordinator
    let libERC721Factory
    let libERC1155Factory
    let libFaithful

    before(async function () {
      diamondAddress = await deployDiamond()
      libERC721Factory = await ethers.getContractFactory('LibERC721')
      libERC1155Factory = await ethers.getContractFactory('LibERC1155')
      libFaithful = await ethers.getContractFactory('LibFaithful')
      mockVRFCoordinator = await deployMockVRFCoordinator()
      diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
      diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
      ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
      faithfulFacet = await ethers.getContractAt('FaithfulFacet', diamondAddress)
      vrfFacet = await ethers.getContractAt('VRFFacet', diamondAddress);
    })

    it('should throw exception when chainlink is not initialized', async () => {      
      const [_, addr1] = await ethers.getSigners();
      await expect(faithfulFacet.mint(addr1.address)).to.be.revertedWith("FaithfulFacet: chainlink subscription config is not initialized!");
    })
    
    // init VRF subscription config first
    it('should initialize VRF subscription config', async() => {
      
      await vrfFacet.initializeSubscriber(2796, mockVRFCoordinator.address, 
        "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f",
        100000, 3, 1)
      
      const { s_subscriptionId, vrfCoordinator, keyHash, callbackGasLimit, requestConfirmations, numWords } = await vrfFacet.getSubscriberConfig() 

      assert.equal(s_subscriptionId, 2796, 'subscription id not match')
      assert.equal(vrfCoordinator, mockVRFCoordinator.address, 'vrfCoordinator address not match')
      assert.equal(keyHash, '0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f', 'keyHash not match')
      assert.equal(callbackGasLimit, 100000, 'callbackGasLimit not match')
      assert.equal(requestConfirmations, 3, 'requestConfirmations not match')
      assert.equal(numWords, 1, 'numWords not match')

      assert.isTrue(await vrfFacet.chainlinkInitialized(), 'chainlink subscription not initialized')
    })

    it('should successfully mint before random number fulfills', async() => {
      const faithfulFacet = await ethers.getContractAt('FaithfulFacet', diamondAddress)

      // total supply before mint
      let totalSupply_ = await faithfulFacet.totalSupply()
      assert.equal(totalSupply_, 0);

      // mint execution - for mock, this will only emit RandomWordsRequested event
      const [_, addr1] = await ethers.getSigners();
      await expect(faithfulFacet.mint(addr1.address))
        .to.emit(libERC1155Factory.attach(faithfulFacet.address), 'TransferSingle').withArgs(addr1.address, ethers.constants.AddressZero, addr1.address, 0, 1)
        .to.emit(mockVRFCoordinator, 'RandomWordsRequested');

      // total supply becomes 1
      totalSupply_ = await faithfulFacet.totalSupply()
      assert.equal(totalSupply_, 1)

      // check newly mint Faithful's status & born attribute
      const { randomNumber, status } = await faithfulFacet.getByTokenId(0);

      // staus -- STATUS_VRF_PENDING(1)
      assert.equal(status, 1)  
    })

    it('should call rawRandomFulfilled and render the Faithful', async () => {
      let currentCounter = await mockVRFCoordinator.getCounter()

      const [_, addr1] = await ethers.getSigners()
      await expect(mockVRFCoordinator.fulfillRandomWords(currentCounter, diamondAddress))
        .to.emit(libFaithful.attach(vrfFacet.address), 'FaithfulRendered').withArgs(addr1.address, 0, currentCounter)
      
      // check the newly rendered Faithful's attribute
      const { randomNumber, status, attack, defense, fortune } = await faithfulFacet.getByTokenId(0);

      // status -- STATUS_RUNNING(2)
      assert.equal(status, 2)
      assert.equal(attack, randomNumber % 10)
      assert.equal(defense, (Math.trunc(randomNumber / 10) % 10))
      assert.equal(fortune, (Math.trunc(randomNumber / 100) % 10))

    })
    
})

const deployMockVRFCoordinator = async () => {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  console.log('start deploying mock VRF cooridinator...')
  const MockVRFCoordinator = await ethers.getContractFactory('MockVRFCoordinator')
  const mockVRFCoordinator = await MockVRFCoordinator.deploy()
  await mockVRFCoordinator.deployed()

  console.log('mock VRF cooridinator deployed, address: ', mockVRFCoordinator.address)
  return mockVRFCoordinator
}