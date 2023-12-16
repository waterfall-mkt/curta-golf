<img align="right" width="150" height="150" top="100" src="./assets/curta-golf.webp">

# Curta
[**Website**](https://curta.wtf?tab=golf) - [**Docs**](https://curta.wtf/docs/golf/overview) - [**Twitter**](https://twitter.com/curta_ctf)

A king-of-the-hill style competition, where players optimize gas challenges.

The goal of players is to view [**Courses**](https://github.com/waterfall-mkt/curta-golf-courses) (challenges) and try to implement the most optimized solution for it. If the solution is valid, a **Par Token** with the corresponding metadata will be minted to their address. If it's the most efficient, they will be crowned the "King," and **King** NFT will be transferred to them.

## Deployments

<table>
    <thead>
        <tr>
            <th>Chain</th>
            <th>Chain ID</th>
            <th>Contract</th>
            <th>Deploy</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td rowspan="3">Base</td>
            <td rowspan="3">8453</td>
            <td><code><a href="https://github.com/waterfall-mkt/curta-golf/blob/1449e59227a30ca720c04785339406515a0a2fea/src/CurtaGolf.sol">CurtaGolf</a></code></td>
            <td><code><a href="https://basescan.org/address/0x537b3D527Ef128Bbb9A7d4fD68A40BA1122ff9D3">0x537b3D527Ef128Bbb9A7d4fD68A40BA1122ff9D3</code></td>
        </tr>
        <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta-golf/blob/1449e59227a30ca720c04785339406515a0a2fea/src/Par.sol">Par</a></code></td>
            <td><code><a href="https://basescan.org/address/0x33387c2bd677e716a42AAeE357dD77f3b733Ae85">0x33387c2bd677e716a42AAeE357dD77f3b733Ae85</code></td>
        </tr>
        <tr>
            <td><code><a href="https://github.com/waterfall-mkt/curta-golf/blob/1449e59227a30ca720c04785339406515a0a2fea/src/utils/PurityChecker.sol">PurityChecker</a></code></td>
            <td><code><a href="https://basescan.org/address/ 0xE03Bbdb59444581f54f6823F0091FdF738E3Ce62"> 0xE03Bbdb59444581f54f6823F0091FdF738E3Ce62</code></td>
        </tr>
    </tbody>
<table>

## Usage
This project uses [**Foundry**](https://github.com/foundry-rs/foundry) as its development/testing framework.

### Installation

First, make sure you have Foundry installed. Then, run the following commands to clone the repo and install its dependencies:
```sh
git clone https://github.com/waterfall-mkt/curta-golf.git
cd curta-golf
forge install
```

### Testing
To run tests, run the following command:
```sh
forge test
```

To test the metadata output for `King` and `Art`, run the following commands:
```sh
forge script script/metadata/PrintKingArt.s.sol:PrintKingArtScript --via-ir -vvv
forge script script/metadata/PrintPartArt.s.sol:PrintPartArtScript --via-ir -vvv
```

### Coverage
To view coverage, run the following command:
```sh
forge coverage
```

To generate a report, run the following command:
```sh
forge coverage --report lcov
```

> **Note**
> It may be helpful to use an extension like [**Coverage Gutters**](https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters) to display the coverage over the code.

## Acknowledgements
* [**Optimizor Club**](https://github.com/OptimizorClub/optimizor)
* [**axic/puretea**](https://github.com/axic/puretea/)
