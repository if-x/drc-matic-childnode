/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import BN from "bn.js";
import { EventData, PastEventOptions } from "web3-eth-contract";

export interface BaseERC20Contract extends Truffle.Contract<BaseERC20Instance> {
  "new"(meta?: Truffle.TransactionDetails): Promise<BaseERC20Instance>;
}

export interface ChildChainChanged {
  name: "ChildChainChanged";
  args: {
    previousAddress: string;
    newAddress: string;
    0: string;
    1: string;
  };
}

export interface Deposit {
  name: "Deposit";
  args: {
    token: string;
    from: string;
    amount: BN;
    input1: BN;
    output1: BN;
    0: string;
    1: string;
    2: BN;
    3: BN;
    4: BN;
  };
}

export interface LogFeeTransfer {
  name: "LogFeeTransfer";
  args: {
    token: string;
    from: string;
    to: string;
    amount: BN;
    input1: BN;
    input2: BN;
    output1: BN;
    output2: BN;
    0: string;
    1: string;
    2: string;
    3: BN;
    4: BN;
    5: BN;
    6: BN;
    7: BN;
  };
}

export interface LogTransfer {
  name: "LogTransfer";
  args: {
    token: string;
    from: string;
    to: string;
    amount: BN;
    input1: BN;
    input2: BN;
    output1: BN;
    output2: BN;
    0: string;
    1: string;
    2: string;
    3: BN;
    4: BN;
    5: BN;
    6: BN;
    7: BN;
  };
}

export interface OwnershipTransferred {
  name: "OwnershipTransferred";
  args: {
    previousOwner: string;
    newOwner: string;
    0: string;
    1: string;
  };
}

export interface ParentChanged {
  name: "ParentChanged";
  args: {
    previousAddress: string;
    newAddress: string;
    0: string;
    1: string;
  };
}

export interface Withdraw {
  name: "Withdraw";
  args: {
    token: string;
    from: string;
    amount: BN;
    input1: BN;
    output1: BN;
    0: string;
    1: string;
    2: BN;
    3: BN;
    4: BN;
  };
}

type AllEvents =
  | ChildChainChanged
  | Deposit
  | LogFeeTransfer
  | LogTransfer
  | OwnershipTransferred
  | ParentChanged
  | Withdraw;

export interface BaseERC20Instance extends Truffle.ContractInstance {
  EIP712_DOMAIN_HASH(txDetails?: Truffle.TransactionDetails): Promise<string>;

  EIP712_DOMAIN_SCHEMA_HASH(
    txDetails?: Truffle.TransactionDetails
  ): Promise<string>;

  EIP712_TOKEN_TRANSFER_ORDER_SCHEMA_HASH(
    txDetails?: Truffle.TransactionDetails
  ): Promise<string>;

  changeChildChain: {
    (newAddress: string, txDetails?: Truffle.TransactionDetails): Promise<
      Truffle.TransactionResponse<AllEvents>
    >;
    call(
      newAddress: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      newAddress: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      newAddress: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  childChain(txDetails?: Truffle.TransactionDetails): Promise<string>;

  deposit: {
    (
      user: string,
      amountOrTokenId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      user: string,
      amountOrTokenId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      user: string,
      amountOrTokenId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      user: string,
      amountOrTokenId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  disabledHashes(
    arg0: string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<boolean>;

  ecrecovery(
    hash: string,
    sig: string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<string>;

  getTokenTransferOrderHash(
    spender: string,
    tokenIdOrAmount: number | BN | string,
    data: string,
    expiration: number | BN | string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<string>;

  /**
   * @returns true if `msg.sender` is the owner of the contract.
   */
  isOwner(txDetails?: Truffle.TransactionDetails): Promise<boolean>;

  /**
   * @returns the address of the owner.
   */
  owner(txDetails?: Truffle.TransactionDetails): Promise<string>;

  parent(txDetails?: Truffle.TransactionDetails): Promise<string>;

  /**
   * Allows the current owner to relinquish control of the contract. It will not be possible to call the functions with the `onlyOwner` modifier anymore.
   * Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.
   */
  renounceOwnership: {
    (txDetails?: Truffle.TransactionDetails): Promise<
      Truffle.TransactionResponse<AllEvents>
    >;
    call(txDetails?: Truffle.TransactionDetails): Promise<void>;
    sendTransaction(txDetails?: Truffle.TransactionDetails): Promise<string>;
    estimateGas(txDetails?: Truffle.TransactionDetails): Promise<number>;
  };

  setParent: {
    (newAddress: string, txDetails?: Truffle.TransactionDetails): Promise<
      Truffle.TransactionResponse<AllEvents>
    >;
    call(
      newAddress: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      newAddress: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      newAddress: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  token(txDetails?: Truffle.TransactionDetails): Promise<string>;

  /**
   * Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  transferOwnership: {
    (newOwner: string, txDetails?: Truffle.TransactionDetails): Promise<
      Truffle.TransactionResponse<AllEvents>
    >;
    call(
      newOwner: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      newOwner: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      newOwner: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  withdraw: {
    (
      amountOrTokenId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      amountOrTokenId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      amountOrTokenId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      amountOrTokenId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  transferWithSig: {
    (
      sig: string,
      amount: number | BN | string,
      data: string,
      expiration: number | BN | string,
      to: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      sig: string,
      amount: number | BN | string,
      data: string,
      expiration: number | BN | string,
      to: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    sendTransaction(
      sig: string,
      amount: number | BN | string,
      data: string,
      expiration: number | BN | string,
      to: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      sig: string,
      amount: number | BN | string,
      data: string,
      expiration: number | BN | string,
      to: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  balanceOf(
    account: string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<BN>;

  methods: {
    EIP712_DOMAIN_HASH(txDetails?: Truffle.TransactionDetails): Promise<string>;

    EIP712_DOMAIN_SCHEMA_HASH(
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;

    EIP712_TOKEN_TRANSFER_ORDER_SCHEMA_HASH(
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;

    changeChildChain: {
      (newAddress: string, txDetails?: Truffle.TransactionDetails): Promise<
        Truffle.TransactionResponse<AllEvents>
      >;
      call(
        newAddress: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        newAddress: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        newAddress: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    childChain(txDetails?: Truffle.TransactionDetails): Promise<string>;

    deposit: {
      (
        user: string,
        amountOrTokenId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        user: string,
        amountOrTokenId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        user: string,
        amountOrTokenId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        user: string,
        amountOrTokenId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    disabledHashes(
      arg0: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<boolean>;

    ecrecovery(
      hash: string,
      sig: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;

    getTokenTransferOrderHash(
      spender: string,
      tokenIdOrAmount: number | BN | string,
      data: string,
      expiration: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;

    /**
     * @returns true if `msg.sender` is the owner of the contract.
     */
    isOwner(txDetails?: Truffle.TransactionDetails): Promise<boolean>;

    /**
     * @returns the address of the owner.
     */
    owner(txDetails?: Truffle.TransactionDetails): Promise<string>;

    parent(txDetails?: Truffle.TransactionDetails): Promise<string>;

    /**
     * Allows the current owner to relinquish control of the contract. It will not be possible to call the functions with the `onlyOwner` modifier anymore.
     * Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.
     */
    renounceOwnership: {
      (txDetails?: Truffle.TransactionDetails): Promise<
        Truffle.TransactionResponse<AllEvents>
      >;
      call(txDetails?: Truffle.TransactionDetails): Promise<void>;
      sendTransaction(txDetails?: Truffle.TransactionDetails): Promise<string>;
      estimateGas(txDetails?: Truffle.TransactionDetails): Promise<number>;
    };

    setParent: {
      (newAddress: string, txDetails?: Truffle.TransactionDetails): Promise<
        Truffle.TransactionResponse<AllEvents>
      >;
      call(
        newAddress: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        newAddress: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        newAddress: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    token(txDetails?: Truffle.TransactionDetails): Promise<string>;

    /**
     * Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    transferOwnership: {
      (newOwner: string, txDetails?: Truffle.TransactionDetails): Promise<
        Truffle.TransactionResponse<AllEvents>
      >;
      call(
        newOwner: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        newOwner: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        newOwner: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    withdraw: {
      (
        amountOrTokenId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        amountOrTokenId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        amountOrTokenId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        amountOrTokenId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    transferWithSig: {
      (
        sig: string,
        amount: number | BN | string,
        data: string,
        expiration: number | BN | string,
        to: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        sig: string,
        amount: number | BN | string,
        data: string,
        expiration: number | BN | string,
        to: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      sendTransaction(
        sig: string,
        amount: number | BN | string,
        data: string,
        expiration: number | BN | string,
        to: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        sig: string,
        amount: number | BN | string,
        data: string,
        expiration: number | BN | string,
        to: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    balanceOf(
      account: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN>;
  };

  getPastEvents(event: string): Promise<EventData[]>;
  getPastEvents(
    event: string,
    options: PastEventOptions,
    callback: (error: Error, event: EventData) => void
  ): Promise<EventData[]>;
  getPastEvents(event: string, options: PastEventOptions): Promise<EventData[]>;
  getPastEvents(
    event: string,
    callback: (error: Error, event: EventData) => void
  ): Promise<EventData[]>;
}
