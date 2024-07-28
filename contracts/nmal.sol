// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NLGmal {
    string constant NLGmal_chars = "0123456789mnopqrstuvwxyz";
    uint8 constant base = 24;

    function decimalToNlgmal(uint256 decimal) public pure returns (string memory) {
        if (decimal == 0) {
            return "0";
        }

        bytes memory nlgmal = new bytes(78); // Max length for uint256
        uint256 i = nlgmal.length;
        while (decimal > 0) {
            --i;
            nlgmal[i] = bytes(NLGmal_chars)[decimal % base];
            decimal /= base;
        }

        bytes memory result = new bytes(nlgmal.length - i);
        for (uint256 j = 0; j < result.length; j++) {
            result[j] = nlgmal[i + j];
        }

        return string(result);
    }

    function nlgmalToDecimal(string memory nlgmal) public pure returns (uint256) {
        bytes memory nlgmalBytes = bytes(nlgmal);
        uint256 decimal = 0;

        for (uint256 i = 0; i < nlgmalBytes.length; i++) {
            uint8 charValue = uint8(charToValue(nlgmalBytes[i]));
            decimal = decimal * base + charValue;
        }

        return decimal;
    }

    function charToValue(bytes1 char) internal pure returns (uint8) {
        if (char >= 0x30 && char <= 0x39) {
            return uint8(char) - 0x30;
        } else if (char >= 0x6D && char <= 0x7A) {
            return uint8(char) - 0x6D + 10;
        } else if (char >= 0x4D && char <= 0x5A) {
            // Handle capital letters
            return uint8(char) - 0x4D + 10;
        } else {
            revert("Invalid character");
        }
    }

    function bytesToNlgdecimal(bytes memory byteData) public pure returns (string memory) {
        uint256 decimalNumber = bytesToUint256(byteData);
        return decimalToNlgmal(decimalNumber);
    }

    function nlgdecimalToBytes(string memory nlgdecimal) public pure returns (bytes memory) {
        uint256 decimalNumber = nlgmalToDecimal(nlgdecimal);
        return uint256ToBytes(decimalNumber);
    }

    function bytesToUint256(bytes memory _bytes) internal pure returns (uint256) {
        require(_bytes.length <= 32, "bytesToUint256_outOfBounds");
        uint256 result;
        assembly {
            result := mload(add(_bytes, 32))
        }
        return result;
    }

    function uint256ToBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
}
