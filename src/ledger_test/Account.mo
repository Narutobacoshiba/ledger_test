import Array     "mo:base/Array";
import Blob      "mo:base/Blob";
import Nat8      "mo:base/Nat8";
import Nat32     "mo:base/Nat32";
import Principal "mo:base/Principal";
import Text      "mo:base/Text";
import CRC32     "./CRC32";
import SHA224    "./SHA224";

module {
  // 32-byte array.
  public type AccountIdentifier = Blob;
  // 32-byte array.
  public type Subaccount = Blob;

  func beBytes(n: Nat32) : [Nat8] {
    func byte(n: Nat32) : Nat8 {
      Nat8.fromNat(Nat32.toNat(n & 0xff))
    };
    [byte(n >> 24), byte(n >> 16), byte(n >> 8), byte(n)]
  };

  public func defaultSubaccount() : Subaccount {
    Blob.fromArrayMut(Array.init(32, 0 : Nat8))
  };

  public func accountIdentifier(principal: Principal, subaccount: Subaccount) : AccountIdentifier {
    let hash = SHA224.Digest();
    hash.write([0x0A]);
    hash.write(Blob.toArray(Text.encodeUtf8("account-id")));
    hash.write(Blob.toArray(Principal.toBlob(principal)));
    hash.write(Blob.toArray(subaccount));
    let hashSum = hash.sum();
    let crc32Bytes = beBytes(CRC32.ofArray(hashSum));
    Blob.fromArray(Array.append(crc32Bytes, hashSum))
  };

  public func validateAccountIdentifier(accountIdentifier : AccountIdentifier) : Bool {
    if (accountIdentifier.size() != 32) {
      return false;
    };
    let a = Blob.toArray(accountIdentifier);
    let accIdPart    = Array.tabulate(28, func(i: Nat): Nat8 { a[i + 4] });
    let checksumPart = Array.tabulate(4,  func(i: Nat): Nat8 { a[i] });
    let crc32 = CRC32.ofArray(accIdPart);
    Array.equal(beBytes(crc32), checksumPart, Nat8.equal)
  };

  public type Tokens = {
     e8s : Nat64;
  };

  type Memo = Nat64;

  type TimeStamp = {
    timestamp_nanos: Nat64;
  };

  type BlockIndex = Nat64;


  type Operation = {
    #Mint : {
        to : AccountIdentifier;
        amount : Tokens;
    };
    #Burn : {
        from : AccountIdentifier;
        amount : Tokens;
    };
    #Transfer : {
        from : AccountIdentifier;
        to : AccountIdentifier;
        amount : Tokens;
        fee : Tokens;
    };
  };

  type Transaction = {
    memo : Memo;
    operation : Operation;
    created_at_time : TimeStamp;
  };

  public type Block = {
    parent_hash : Blob;
    transaction : Transaction;
    timestamp : TimeStamp;
  };

  // Account Balance ledger args
  public type AccountBalanceArgs = {
    account: AccountIdentifier;
  };


  // Transfers ledger args
  type TransferError = {
    #BadFee : { expected_fee : Tokens; };
    #InsufficientFunds : { balance: Tokens; };
    #TxTooOld : { allowed_window_nanos: Nat64 };
    #TxCreatedInFuture : Null;
    #TxDuplicate : { duplicate_of: BlockIndex; }
  };
  public type TransferArgs = {
    memo: Memo;
    amount: Tokens;
    fee: Tokens;
    to: Principal;
  };
  public type TransferResult = {
    #Ok : BlockIndex;
    #Err : TransferError;
  };

  public type GetBlocksArgs = {
    start : BlockIndex;
    length : Nat64;
  };
  type BlockRange = {
    blocks : [Block];
  };
  type QueryArchiveError = {
    #BadFirstBlockIndex : {
        requested_index : BlockIndex;
        first_valid_index : BlockIndex;
    };
    #Other : {
        error_code : Nat64;
        error_message : Text;
    };
  };

  type QueryArchiveResult = {
    #Ok : BlockRange;
    #Err : QueryArchiveError;
  };

  type QueryArchiveFn = (GetBlocksArgs) -> (QueryArchiveResult);

  public type QueryBlocksResponse = {
    chain_length : Nat64;
    certificate : ?Blob;
    //blocks : [Block];
    first_block_index : Nat64;
  };


}
