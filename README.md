# ☯️ Oracle-book-via-diamond-3-hardhat

This is a toy example based on @mudgen's [Diamond-3-Hardhat Implementation](https://github.com/mudgen/diamond-3-hardhat), a forked NFT project to explore as more Smart Contract features as we can.

# 👨🏻‍💻 Developer notes for AppStorage based Diamond Implementation

For developers who wants to add new feature(facet), please give a round tour about your implementation in your mind and figure out what the storage structure is to fulfill requirements. And then check out `./contracts/oracle_book_contracts/libs/LibAppStorage` to define your storage design inside the `AppStorage` struct.

After that, you are free to implement your logic in the facet as you like. 

Please MAKE SURE that you ONLY can have AppStorage field in your facet. That is ONE and ONLY, NOTHING ELSE, or it will make storage collisions.

🚨 Also unit tests should be included for every facet implementations~

Enjoy your exploration in Diamond Contract!

# 🧙🏻 Get Started

## Installation
1. Clone this repo:

```
git clone git@github.com:daibi/oracle-book-via-diamond-3-hardhat.git
```

2. Install NPM packages:
```
cd diamond-3-hardhat
npm install
```

## Run Tests

To run the unit test via hardhat: (make sure that all files are compiled after change)
```
npx hardhat compile
npx hardhat test
```

## License

MIT license. See the license file.
Anyone can use or modify this software for their purposes.

