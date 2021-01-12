// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

import "./SafeMath.sol";

library ArrayHelper {
  using SafeMath for uint256;

  function addTwoArrays(uint256[] memory array1, uint256[] memory array2) internal pure returns (uint256[] memory) {
    uint256[] memory array3 = new uint256[](array1.length);
    for (uint256 i = 0; i < array1.length; i++) {
      array3[i] = array1[i].add(array2[i]);
    }
    return array3;
  }

  function subTwoArrays(uint256[] memory array1, uint256[] memory array2) internal pure returns (uint256[] memory) {
    uint256[] memory array3 = new uint256[](array1.length);
    for (uint256 i = 0; i < array1.length; i++) {
      array3[i] = array1[i].sub(array2[i]);
    }
    return array3;
  }

  function fillArrays(uint256 num, uint256 length) internal pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](length);
    for (uint256 i = 0; i < length; i++) {
      array[i] = num;
    }
    return array;
  }
}
