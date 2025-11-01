// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {ManageCluster} from "./ManageCluster.s.sol";
import {OracleVerifier} from "../../../utils/SanityCheckOracle.s.sol";
import {ClusterDump} from "../../../utils/ClusterDump.s.sol";

contract Cluster is ManageCluster {
    function defineCluster() internal override {
        // define the path to the cluster addresses file here
        cluster.clusterAddressesPath = "/script/production/mainnet/clusters/ynRWAxCluster.json";

        // do not change the order of the assets in the .assets array. if done, it must be reflected in other the other arrays the ltvs matrix.
        // if more than one vauls has to be deployed for the same asset, it can be added in the array as many times as needed.
        // note however, that mappings may need reworking as they always use asset address as key.
        cluster.assets = [
            USDC,
            ynRWAx,
            ynUSDx
        ];
    }

    function configureCluster() internal override {
        // define the governors here
        //cluster.oracleRoutersGovernor = cluster.vaultsGovernor = governorAddresses.accessControlEmergencyGovernor;
        cluster.oracleRoutersGovernor = cluster.vaultsGovernor = 0xfcad670592a3b24869C0b51a6c6FDED4F95D6975;

        // define unit of account here
        cluster.unitOfAccount = USDC;

        // define fee receiver here and interest fee here. if needed to be defined per asset, populate the feeReceiverOverride and interestFeeOverride mappings
        // YieldNest ETH L1 Mainnet Fee Receiver
        cluster.feeReceiver = 0xC92Dd1837EBcb0365eB0a8795f9c8E474f8B6183;
        cluster.interestFee = 0.1e4;

        // define max liquidation discount here. if needed to be defined per asset, populate the maxLiquidationDiscountOverride mapping
        cluster.maxLiquidationDiscount = 0.15e4;

        // define liquidation cool off time here. if needed to be defined per asset, populate the liquidationCoolOffTimeOverride mapping
        cluster.liquidationCoolOffTime = 1;

        // define hook target and hooked ops here. if needed to be defined per asset, populate the hookTargetOverride and hookedOpsOverride mappings
        cluster.hookTarget = address(0);
        cluster.hookedOps = 0;

        // define config flags here. if needed to be defined per asset, populate the configFlagsOverride mapping
        cluster.configFlags = 0;

        // define oracle providers here. 
        // adapter names can be found in the relevant adapter contract (as returned by the `name` function).
        // for cross adapters, use the following format: "CrossAdapter=<adapterName1>+<adapterName2>".
        // although Redstone Classic oracles reuse the ChainlinkOracle contract and returns "ChainlinkOracle" name, 
        // they should be referred to as "RedstoneClassicOracle".
        // in case the asset is an ERC4626 vault itself (i.e. sUSDS) and is recognized as a valid external vault as per 
        // External Vaults Registry, the string should be preceeded by "ExternalVault|" prefix. this is in order to resolve 
        // the asset (vault) in the oracle router.
        // in case the adapter is not present in the Adapter Registry, the adapter address can be passed instead in form of a string.

        // FixedRate oracle for USDC (rates are in USDC)
        cluster.oracleProviders[USDC  ] = "0xB92B9341be191895e8C68b170aC4528839fFe0b2";

        // TODO: fix this to have the correct oracle provider
        cluster.oracleProviders[ynRWAx  ] = "ExternalVault|";
        // TODO: fix this to have the correct oracle provider
        cluster.oracleProviders[ynUSDx ] = "ExternalVault|";

        // define supply caps here. 0 means no supply can occur, type(uint256).max means no cap defined hence max amount
        cluster.supplyCaps[USDC  ] = type(uint256).max; 
        cluster.supplyCaps[ynRWAx  ] = type(uint256).max;
        cluster.supplyCaps[ynUSDx ] = type(uint256).max;

        // define borrow caps here. 0 means no borrow can occur, type(uint256).max means no cap defined hence max amount
        cluster.borrowCaps[USDC  ] = type(uint256).max;
        cluster.borrowCaps[ynRWAx  ] = type(uint256).max;
        cluster.borrowCaps[ynUSDx ] = type(uint256).max;

        // define IRM classes here and assign them to the assets
        {
            // Base=0% APY  Kink(90%)=4.3% APY  Max=15.00% APY
            uint256[4] memory irm = [uint256(0), uint256(345139759), uint256(7205461616), uint256(3865470566)];
            
            cluster.kinkIRMParams[USDC  ] = irm;
            cluster.kinkIRMParams[ynRWAx  ] = irm;
            cluster.kinkIRMParams[ynUSDx ] = irm;
        }

        // define the ramp duration to be used, in case the liquidation LTVs have to be ramped down
        cluster.rampDuration = 1 days;

        // define the spread between borrow and liquidation ltv
        cluster.spreadLTV = 0.01e4;
    
        // define ltv values here. columns are liability vaults, rows are collateral vaults
        cluster.ltvs = [
        //               0               1       2      
        //               USDC            ynRWAx    ynUSDx  
        /* 0  USDC   */ [uint16(0.00e4), 0.95e4, 0.95e4],
        /* 1  ynRWAx   */ [uint16(0.95e4), 0.00e4, 0.95e4],
        /* 2  ynUSDx  */ [uint16(0.95e4), 0.95e4, 0.00e4]
        ];
    }

    function postOperations() internal view override {
        for (uint256 i = 0; i < cluster.vaults.length; ++i) {
            OracleVerifier.verifyOracleConfig(lensAddresses.oracleLens, cluster.vaults[i], false);
        }
    }
}
