import "./Bytes.sol";
import "./TypedMemView.sol";

library CCTPMessage {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;
    using Bytes for bytes;

    uint8 public constant SOURCE_DOMAIN_INDEX = 4;
    uint8 public constant NONCE_INDEX = 12;
    uint8 public constant SENDER_INDEX = 20;
    uint8 public constant DESTINATION_CALLER_INDEX = 84;
    uint8 public constant MESSAGE_BODY_INDEX = 116;

    function _sourceDomain(bytes29 _messageRef) private pure returns (uint32) {
        return uint32(_messageRef.indexUint(SOURCE_DOMAIN_INDEX, 4));
    }

    function sourceDomain(bytes memory _message) public pure returns (uint32) {
        return _sourceDomain(_message.ref(0));
    }

    function _nonce(bytes29 _messageRef) private pure returns (uint64) {
        return uint64(_messageRef.indexUint(NONCE_INDEX, 8));
    }

    function nonce(bytes memory _message) public pure returns (uint64) {
        return _nonce(_message.ref(0));
    }

    function _sender(bytes29 _messageRef) private pure returns (bytes32) {
        return _messageRef.index(SENDER_INDEX, 32);
    }

    function sender(bytes memory _message) public pure returns (bytes32) {
        return _sender(_message.ref(0));
    }

    function _destinationCaller(
        bytes29 _message
    ) private pure returns (bytes32) {
        return _message.index(DESTINATION_CALLER_INDEX, 32);
    }

    function destinationCaller(
        bytes memory _message
    ) public pure returns (bytes32) {
        return _destinationCaller(_message.ref(0));
    }

    function body(bytes memory message) public pure returns (bytes memory) {
        return
            message.slice(
                MESSAGE_BODY_INDEX,
                message.length - MESSAGE_BODY_INDEX
            );
    }
}
