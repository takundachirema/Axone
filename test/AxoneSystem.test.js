// Import all required modules from openzeppelin-test-helpers
const truffleAssert = require('truffle-assertions')

const {
    BN,
    constants,
    expectEvent,
    expectRevert,
    ether,
    time
} = require("@openzeppelin/test-helpers");
const {
    expect
} = require("chai");

const BigNumber = require('bignumber.js');

let Decimal = require("decimal.js");
Decimal.set({
    precision: 100,
    rounding: Decimal.ROUND_DOWN
});

// UniCoin Contracts
const AxoneManager = artifacts.require("./AxoneManager.sol");
const UserManager = artifacts.require("./UserManager.sol");
const AssetManager = artifacts.require("./AssetManager.sol");
const RevenueManager = artifacts.require("./RevenueManager.sol");

// Mock Contracts
// const Erc20Mock = artifacts.require("./Mocks/ERC20Mock.sol");

contract("Axone Registry Full system test 🧪🔬", (accounts) => {
    const registryOwner = accounts[0]
    const owner_1 = accounts[1]
    const owner_2 = accounts[2]
    const owner_3 = accounts[3]
    const owner_4 = accounts[4]
    const owner_5 = accounts[5]
    const owner_6 = accounts[6]
    const randomAddress = accounts[7]
    const tokenOwner = accounts[8]
    //constants
    const exampleUserProfileURI = "QmeWUs9YdymQVpsme3MLQdWFW5GjdM4XDFYMi3YJvUFiaq"
    const asset_uri_1 = "QmPF7eAtGoaEgSAt9XCP2DuWfc8sbtQfraffDsx3svu4P1"
    const asset_uri_2 = "QmQjkpEFWEWQz4KxUmG8U3hrJe5KmCTyWCVVXAjcQJST22"
    const asset_uri_3 = "QmPF7eAtGoaEgSAt9XCP2DuWfc8sbtQfraffDsx3svu4P3"
    const asset_uri_4 = "QmQjkpEFWEWQz4KxUmG8U3hrJe5KmCTyWCVVXAjcQJST24"
    const asset_uri_5 = "QmPF7eAtGoaEgSAt9XCP2DuWfc8sbtQfraffDsx3svu4P5"
    const asset_uri_6 = "QmQjkpEFWEWQz4KxUmG8U3hrJe5KmCTyWCVVXAjcQJST26"
    const asset_uri_7 = "QmPF7eAtGoaEgSAt9XCP2DuWfc8sbtQfraffDsx3svu4P7"
    const asset_uri_8 = "QmQjkpEFWEWQz4KxUmG8U3hrJe5KmCTyWCVVXAjcQJST28"

    var asset_id_1, asset_id_2, asset_id_3, asset_id_4, asset_id_5, asset_id_6, asset_id_7, asset_id_8
    var owner_id_1, owner_id_2, owner_id_3, owner_id_4, owner_id_5, owner_id_6;
    var owner_1_bal, owner_2_bal, owner_3_bal, owner_4_bal, owner_5_bal, owner_6_bal;
    
    const oneMonthSeconds = 60 * 60 * 24 * 30

    before(async function () {

        // Initialize contracts
        axoneManager = await AxoneManager.new()

        userManager = await UserManager.new()
        userManager.initialize(axoneManager.address)

        assetManager = await AssetManager.new()
        assetManager.initialize(axoneManager.address)

        revenueManager = await RevenueManager.new()
        revenueManager.initialize(axoneManager.address)

        await axoneManager.initialize(
            userManager.address,
            revenueManager.address,
            assetManager.address)
    });

    beforeEach(async function () {

    })

    // Tests correct registration of users
    context("User Management 💁‍♂️", function () {
        it("Reverts if invalid user input", async () => {
            await expectRevert.unspecified(axoneManager.registerUser("", {
                from: owner_1
            }))
        });
        it("Can add new user", async () => {
            await axoneManager.registerUser(exampleUserProfileURI, {
                from: owner_1
            })
            owner_id_1 = await axoneManager.getCallerId.call({from: owner_1})

            await axoneManager.registerUser(exampleUserProfileURI, {
                from: owner_2
            })
            owner_id_2 = await axoneManager.getCallerId.call({from: owner_2})

            await axoneManager.registerUser(exampleUserProfileURI, {
                from: owner_3
            })
            owner_id_3 = await axoneManager.getCallerId.call({from: owner_3})

            await axoneManager.registerUser(exampleUserProfileURI, {
                from: owner_4
            })
            owner_id_4 = await axoneManager.getCallerId.call({from: owner_4})

            await axoneManager.registerUser(exampleUserProfileURI, {
                from: owner_5
            })
            owner_id_5 = await axoneManager.getCallerId.call({from: owner_5})

            await axoneManager.registerUser(exampleUserProfileURI, {
                from: owner_6
            })
            owner_id_6 = await axoneManager.getCallerId.call({from: owner_6})

        });
        it("Revert if user already added", async () => {
            await expectRevert.unspecified(axoneManager.registerUser(exampleUserProfileURI, {
                from: owner_1
            }))
        });
        it("Can retrieve user profile information", async () => {
            let isAddressRegistered = await axoneManager.isCallerRegistered.call({
                from: owner_1
            })
            assert.equal(isAddressRegistered, true, "User should be registered")

            isAddressRegistered = await axoneManager.isCallerRegistered.call({
                from: randomAddress
            })
            assert.equal(isAddressRegistered, false, "User should not be registered")

            let owner1CallerId = await axoneManager.getCallerId({
                from: owner_2
            })
            assert.equal(owner1CallerId.toNumber(), 2, "owner_2 Id not set correctly")

            let returnedOwner1Address = await axoneManager.getUserAddress(2)
            assert.equal(returnedOwner1Address, owner_2, "owner_2 address increctly returned")
        })
    })
    context("Asset Management ‍📚", function () {
        it("Can create a valid asset", async () => {
            let txn = await axoneManager.createAsset(asset_uri_1,0,[],[],[],[],{
                from: owner_2
            });
            truffleAssert.eventEmitted(txn, 'NewAsset', (ev) => {
                asset_id_1 = ev.asset_id
                return true
            });
            assert.equal(asset_id_1, 1, "asset id is not 1");
        })
    })
    context("Asset Management: Reject on negative input 🙅‍♂️‍", function () {
        it("Reverts if invalid asset: input non-registered user", async () => {
            await expectRevert.unspecified(
                axoneManager.createAsset.call(asset_uri_1,0,[],[],[],[],{
                    from: randomAddress
                })
            )
        })
        it("Reverts if invalid asset: input URI too short", async () => {
            await expectRevert.unspecified(
                axoneManager.createAsset.call("",0,[],[],[],[],{
                    from: randomAddress
                })
            )
        })
    })
    context("Asset Management: add assets 🔎", function () {
        /****** 
         * The number in the bracket is the percentage paid to the node linking
         * on the other end. E.g. 10% is paid by node 5 to node 1.
         * If there are 2 brackets, the node pays to 2 nodes in the order right then left.
         * 
         *    -------(10)5-----  
         *   /                 \
         *  /                   \
         *  1--------(0)2-------(0)(0)3---------------4
         *  \                       \               /
         *   \                       \_____(10)(10)7_____(10)8
         *    \                      /
         *     -------(10)6---------
         * 
        *****/
        it("Can add assets", async () => {
            let txn = await axoneManager.createAsset(
                asset_uri_2,0,[asset_id_1],[0],[],[],
                {from: owner_2}
            );
            truffleAssert.eventEmitted(txn, 'NewAsset', (ev) => {
                asset_id_2 = ev.asset_id
                return true
            });

            txn = await axoneManager.createAsset(
                asset_uri_3,0,[asset_id_2],[0],[],[],
                {from: owner_2}
            );
            truffleAssert.eventEmitted(txn, 'NewAsset', (ev) => {
                asset_id_3 = ev.asset_id
                return true
            });

            txn = await axoneManager.createAsset(
                asset_uri_4,0,[asset_id_3],[0],[],[],
                {from: owner_2}
            );
            truffleAssert.eventEmitted(txn, 'NewAsset', (ev) => {
                asset_id_4 = ev.asset_id
                return true
            });

            txn = await axoneManager.createAsset(
                asset_uri_5,0,[asset_id_1],[10],[asset_id_3],[0],
                {from: owner_3}
            );
            truffleAssert.eventEmitted(txn, 'NewAsset', (ev) => {
                asset_id_5 = ev.asset_id
                return true
            });

            txn = await axoneManager.createAsset(
                asset_uri_6,0,[asset_id_1],[10],[],[],
                {from: owner_4}
            );
            truffleAssert.eventEmitted(txn, 'NewAsset', (ev) => {
                asset_id_6 = ev.asset_id
                return true
            });

            txn = await axoneManager.createAsset(
                asset_uri_7,0,[asset_id_3,asset_id_6],[10,10],[],[],
                {from: owner_5}
            );
            truffleAssert.eventEmitted(txn, 'NewAsset', (ev) => {
                asset_id_7 = ev.asset_id
                return true
            });

            txn = await axoneManager.createAsset(
                asset_uri_8,0,[asset_id_7],[10],[asset_id_4],[0],
                {from: owner_6}
            );
            truffleAssert.eventEmitted(txn, 'NewAsset', (ev) => {
                asset_id_8 = ev.asset_id
                return true
            });
        });
        it("Correctly creates graph", async () => {
            let asset_1 = await axoneManager.getAsset.call(
                asset_id_1
            );
            //console.log(JSON.stringify(asset_1))
            assert.equal(asset_1[0].toNumber(), 1, "Incorrect id for asset 1")
            assert.equal(asset_1[1], asset_uri_1, "Incorrect uri for asset 1")
            assert.equal(asset_1[2].length, 0, "Incorrect parents length for asset 1")
            assert.equal(asset_1[3].length, 3, "Incorrect children length for asset 1")
            assert.equal(asset_1[3][0], 2, "Incorrect child id for asset 1")
            assert.equal(asset_1[5][0], 0, "Incorrect child weight for asset 1")
            assert.equal(asset_1[6].toNumber(), owner_id_2, "Incorrect owner_1 id for asset 1")

            let asset_2 = await axoneManager.getAsset.call(
                asset_id_2
            );
            //console.log(JSON.stringify(asset_2))
            assert.equal(asset_2[0].toNumber(), 2, "Incorrect id for asset 2")
            assert.equal(asset_2[1], asset_uri_2, "Incorrect uri for asset 2")
            assert.equal(asset_2[2].length, 1, "Incorrect parents length for asset 2")
            assert.equal(asset_2[3].length, 1, "Incorrect children length for asset 2")
            assert.equal(asset_2[3][0], 3, "Incorrect child id for asset 2")
            assert.equal(asset_2[5][0], 0, "Incorrect child weight for asset 2")
            assert.equal(asset_2[6].toNumber(), owner_id_2, "Incorrect owner id for asset 2")

            let asset_3 = await axoneManager.getAsset.call(
                asset_id_3
            );
            //console.log(JSON.stringify(asset_3))
            assert.equal(asset_3[0].toNumber(), 3, "Incorrect id for asset 3")
            assert.equal(asset_3[1], asset_uri_3, "Incorrect uri for asset 3")
            assert.equal(asset_3[2].length, 2, "Incorrect parents length for asset 3")
            assert.equal(asset_3[3].length, 2, "Incorrect children length for asset 3")
            assert.equal(asset_3[3][0], 4, "Incorrect child id for asset 3")
            assert.equal(asset_3[5][0], 0, "Incorrect child weight for asset 3")
            assert.equal(asset_3[6].toNumber(), owner_id_2, "Incorrect owner id for asset 3")

            let asset_4 = await axoneManager.getAsset.call(
                asset_id_4
            );
            //console.log(JSON.stringify(asset_4))
            assert.equal(asset_4[0].toNumber(), 4, "Incorrect id for asset 4")
            assert.equal(asset_4[1], asset_uri_4, "Incorrect uri for asset 4")
            assert.equal(asset_4[2].length, 2, "Incorrect parents length for asset 4")
            assert.equal(asset_4[3].length, 0, "Incorrect children length for asset 4")
            assert.equal(asset_4[4][0], 0, "Incorrect parent weight for asset 4")
            assert.equal(asset_4[6].toNumber(), owner_id_2, "Incorrect owner id for asset 4")

            let asset_5 = await axoneManager.getAsset.call(
                asset_id_5
            );
            //console.log(JSON.stringify(asset_5))
            assert.equal(asset_5[0].toNumber(), 5, "Incorrect id for asset 5")
            assert.equal(asset_5[1], asset_uri_5, "Incorrect uri for asset 5")
            assert.equal(asset_5[2].length, 1, "Incorrect parents length for asset 5")
            assert.equal(asset_5[3].length, 1, "Incorrect children length for asset 5")
            assert.equal(asset_5[3][0], 3, "Incorrect child id for asset 5")
            assert.equal(asset_5[4][0], 10, "Incorrect parent weight for asset 5")
            assert.equal(asset_5[6].toNumber(), owner_id_3, "Incorrect owner id for asset 5")

            let asset_6 = await axoneManager.getAsset.call(
                asset_id_6
            );
            //console.log(JSON.stringify(asset_6))
            assert.equal(asset_6[0].toNumber(), 6, "Incorrect id for asset 6")
            assert.equal(asset_6[1], asset_uri_6, "Incorrect uri for asset 6")
            assert.equal(asset_6[2].length, 1, "Incorrect parents length for asset 6")
            assert.equal(asset_6[3].length, 1, "Incorrect children length for asset 6")
            assert.equal(asset_6[3][0], 7, "Incorrect child id for asset 6")
            assert.equal(asset_6[4][0], 10, "Incorrect parent weight for asset 6")
            assert.equal(asset_6[6].toNumber(), owner_id_4, "Incorrect owner id for asset 6")
        
            let asset_7 = await axoneManager.getAsset.call(
                asset_id_7
            );
            //console.log(JSON.stringify(asset_7))
            assert.equal(asset_7[0].toNumber(), 7, "Incorrect id for asset 7")
            assert.equal(asset_7[1], asset_uri_7, "Incorrect uri for asset 7")
            assert.equal(asset_7[2].length, 2, "Incorrect parents length for asset 7")
            assert.equal(asset_7[3].length, 1, "Incorrect children length for asset 7")
            assert.equal(asset_7[3][0], 8, "Incorrect child id for asset 7")
            assert.equal(asset_7[4][0], 10, "Incorrect parent weight for asset 7")
            assert.equal(asset_7[6].toNumber(), owner_id_5, "Incorrect owner id for asset 7")

            let asset_8 = await axoneManager.getAsset.call(
                asset_id_8
            );
            //console.log(JSON.stringify(asset_8))
            assert.equal(asset_8[0].toNumber(), 8, "Incorrect id for asset 8")
            assert.equal(asset_8[1], asset_uri_8, "Incorrect uri for asset 8")
            assert.equal(asset_8[2].length, 1, "Incorrect parents length for asset 8")
            assert.equal(asset_8[3].length, 1, "Incorrect children length for asset 8")
            assert.equal(asset_8[3][0], 4, "Incorrect child id for asset 8")
            assert.equal(asset_8[4][0], 10, "Incorrect parent weight for asset 8")
            assert.equal(asset_8[6].toNumber(), owner_id_6, "Incorrect owner id for asset 8")
        })

        it("Correctly pay for asset", async () => {
            txn = await revenueManager.payForAssetUse(
                asset_id_1,
                {
                    from: randomAddress,
                    value: 50
                }
            );
            txn = await revenueManager.payForAssetUse(
                asset_id_1,
                {
                    from: randomAddress,
                    value: 70
                }
            );
            let asset_1 = await axoneManager.getAsset.call(
                asset_id_1
            );
            let balance = await web3.eth.getBalance(revenueManager.address)
            
            assert.equal(asset_1[8].toNumber(), 100, "Incorrect revenue for asset 1")
            //assert.equal(asset_1[9].toNumber(), 0, "Incorrect gross revenue for asset 1")
            assert.equal(balance, 100, "Incorrect ether in revenue manager")

            txn = await revenueManager.payForAssetUse(
                asset_id_5,
                {
                    from: randomAddress,
                    value: 50
                }
            );
            let asset_5 = await axoneManager.getAsset.call(
                asset_id_5
            );
            balance = await web3.eth.getBalance(revenueManager.address)
            
            assert.equal(asset_5[8].toNumber(), 50, "Incorrect revenue for asset 5")
            //assert.equal(asset_5[9].toNumber(), 50, "Incorrect gross revenue for asset 5")
            assert.equal(balance, 150, "Incorrect ether in revenue manager")

            txn = await revenueManager.payForAssetUse(
                asset_id_7,
                {
                    from: randomAddress,
                    value: 50
                }
            );
            let asset_7 = await axoneManager.getAsset.call(
                asset_id_7
            );
            balance = await web3.eth.getBalance(revenueManager.address)
            
            assert.equal(asset_7[8].toNumber(), 50, "Incorrect revenue for asset 7")
            //assert.equal(asset_7[9].toNumber(), 50, "Incorrect gross revenue for asset 7")
            assert.equal(balance, 200, "Incorrect ether in revenue manager")
        })

        it("Correctly pay royalties", async () => {
             /****** 
             *    -------(10)5-----  
             *   /                 \
             *  /                   \
             *  1--------(0)2-------(0)3---------------4
             *  \                       \             /
             *   \                       \_____(10)(10)7_____(10)8
             *    \                      /
             *     -------(10)6---------
            *****/

            // Get the address balances
            owner_1_bal = BigInt(await web3.eth.getBalance(owner_1));
            owner_2_bal = BigInt(await web3.eth.getBalance(owner_2));
            owner_3_bal = BigInt(await web3.eth.getBalance(owner_3));
            owner_4_bal = BigInt(await web3.eth.getBalance(owner_4));
            owner_5_bal = BigInt(await web3.eth.getBalance(owner_5));
            owner_6_bal = BigInt(await web3.eth.getBalance(owner_6));
            
            await axoneManager.payRoyalties({from: randomAddress});

            let balance = await web3.eth.getBalance(revenueManager.address)
            assert.equal(balance, 0, "Incorrect balance for revenue manager")

            let asset_1 = await axoneManager.getAsset.call(
                asset_id_1
            );
            
            assert.equal(asset_1[8].toNumber(), 0, "Incorrect remaining revenue for asset 1")
            assert.equal(asset_1[9].toNumber(), 100, "Incorrect net revenue for asset 1")
            assert.equal(asset_1[10].toNumber(), 100, "Incorrect gross revenue for asset 1")
            
            balance = await web3.eth.getBalance(owner_2)
            assert.equal(balance, owner_2_bal + BigInt(110), "Incorrect balance for owner 2")

            let asset_5 = await axoneManager.getAsset.call(
                asset_id_5
            );

            assert.equal(asset_5[8].toNumber(), 0, "Incorrect revenue for asset 5")
            assert.equal(asset_5[9].toNumber(), 45, "Incorrect net revenue for asset 5")
            assert.equal(asset_5[10].toNumber(), 50, "Incorrect gross revenue for asset 5")
            
            balance = await web3.eth.getBalance(owner_3)
            assert.equal(balance, owner_3_bal  + BigInt(45), "Incorrect balance for owner 3")

            let asset_7 = await axoneManager.getAsset.call(
                asset_id_7
            );

            assert.equal(asset_7[8].toNumber(), 0, "Incorrect revenue for asset 7")
            assert.equal(asset_7[9].toNumber(), 40, "Incorrect net revenue for asset 7")
            assert.equal(asset_7[10].toNumber(), 50, "Incorrect gross revenue for asset 7")
            
            balance = await web3.eth.getBalance(owner_5)
            assert.equal(balance, owner_5_bal + BigInt(40), "Incorrect balance for owner 5")
        })
    })
})