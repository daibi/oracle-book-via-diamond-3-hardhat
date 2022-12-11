pragma solidity ^0.8.1;

import { SafeMath } from '@openzeppelin/contracts/utils/math/SafeMath.sol';

library LibMath {

    /**
     * recursive power function
     * PLEASE make sure that your operation result NEVER exceeds uint256 range 
     */
    function power(uint256 base, uint256 exponent) internal returns (uint256 result) {
        if (exponent == 0) {
            result = 1;
        } else if (exponent == 1) {
            result = base;
        } else {
            result = power(SafeMath.mul(base, base), SafeMath.div(exponent, 2));
        }
        if (SafeMath.mod(exponent, 2) == 1) {
            result = SafeMath.mul(base, result);
        }
    } 
}