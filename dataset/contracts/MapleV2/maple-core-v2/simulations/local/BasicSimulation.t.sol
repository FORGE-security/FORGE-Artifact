// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { Address } from "../../modules/contract-test-utils/contracts/test.sol";

import { LoanScenario   }              from "../../contracts/LoanScenario.sol";
import { ILoanLike, IPoolManagerLike } from "../../contracts/interfaces/Interfaces.sol";
import { SimulationBase }              from "../../contracts/utilities/SimulationBase.sol";

contract BasicSimulation is SimulationBase {

    function setUp() public override {
        super.setUp();

        initialCover     = 0;
        initialLiquidity = 1_500_000e6;

        scenarios.push(new LoanScenario({
            loan_: address(createLoan({
                borrower:    address(new Address()),
                termDetails: [uint256(0), uint256(30 days), uint256(3)],
                amounts:     [uint256(0), uint256(1_000_000e6), uint256(1_000_000e6)],
                rates:       [uint256(0.01e18), uint256(0), uint256(0), uint256(0)]
            })),
            poolManager_:       address(poolManager),
            liquidatorFactory_: address(liquidatorFactory),
            fundingTime_:       start,
            name_:              "loan-1"
        }));
    }

    function test_basicSimulation() external {
        setUpSimulation("basic");
        simulation.run();
    }

}
