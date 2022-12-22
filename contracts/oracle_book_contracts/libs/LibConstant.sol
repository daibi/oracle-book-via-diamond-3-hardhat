// SPDX-License-Identifier: MIT

library LibConstant {

    /*********************************/
    /****** ERC-1155 Type Enum *******/
    /*********************************/
    uint8 constant FAITHFUL = 1;
    uint8 constant FORTUNE_COOKIE = 2;

    /*********************************/
    /******* Faithful Status *********/
    /*********************************/

    uint8 constant STATUS_INVALID = 0;
    uint8 constant STATUS_VRF_PENDING = 1;
    uint8 constant STATUS_RUNNING = 2;

    /****************************************************/
    /******* Faithful numeric traits SLOT index *********/
    /****************************************************/
    uint8 constant EFFECTIVE_TRAIT_SLOTS = 3;

    uint constant ATTACK_SLOT = 0;
    uint constant DEFENSE_SLOT = 1;
    uint constant FORTUNE_SLOT = 2;


}