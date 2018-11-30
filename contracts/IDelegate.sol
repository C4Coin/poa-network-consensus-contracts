interface IDelegate {
    function join (uint256 stake_amount) public;
    function withdraw () public;
    function withdraw_some (uint256 stake_amount) public;
}
