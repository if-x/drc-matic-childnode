/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import BN from "bn.js";
import { EventData, PastEventOptions } from "web3-eth-contract";

export interface IUniswapV2FactoryContract
  extends Truffle.Contract<IUniswapV2FactoryInstance> {
  "new"(meta?: Truffle.TransactionDetails): Promise<IUniswapV2FactoryInstance>;
}

export interface PairCreated {
  name: "PairCreated";
  args: {
    token0: string;
    token1: string;
    pair: string;

    0: string;
    1: string;
    2: string;
    3: BN;
  };
}

type AllEvents = PairCreated;

export interface IUniswapV2FactoryInstance extends Truffle.ContractInstance {
  feeTo(txDetails?: Truffle.TransactionDetails): Promise<string>;

  feeToSetter(txDetails?: Truffle.TransactionDetails): Promise<string>;

  getPair(
    tokenA: string,
    tokenB: string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<string>;

  allPairs(
    arg0: number | BN | string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<string>;

  allPairsLength(txDetails?: Truffle.TransactionDetails): Promise<BN>;

  createPair: {
    (
      tokenA: string,
      tokenB: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      tokenA: string,
      tokenB: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    sendTransaction(
      tokenA: string,
      tokenB: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      tokenA: string,
      tokenB: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  setFeeTo: {
    (arg0: string, txDetails?: Truffle.TransactionDetails): Promise<
      Truffle.TransactionResponse<AllEvents>
    >;
    call(arg0: string, txDetails?: Truffle.TransactionDetails): Promise<void>;
    sendTransaction(
      arg0: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      arg0: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  setFeeToSetter: {
    (arg0: string, txDetails?: Truffle.TransactionDetails): Promise<
      Truffle.TransactionResponse<AllEvents>
    >;
    call(arg0: string, txDetails?: Truffle.TransactionDetails): Promise<void>;
    sendTransaction(
      arg0: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      arg0: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  methods: {
    feeTo(txDetails?: Truffle.TransactionDetails): Promise<string>;

    feeToSetter(txDetails?: Truffle.TransactionDetails): Promise<string>;

    getPair(
      tokenA: string,
      tokenB: string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;

    allPairs(
      arg0: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;

    allPairsLength(txDetails?: Truffle.TransactionDetails): Promise<BN>;

    createPair: {
      (
        tokenA: string,
        tokenB: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        tokenA: string,
        tokenB: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      sendTransaction(
        tokenA: string,
        tokenB: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        tokenA: string,
        tokenB: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    setFeeTo: {
      (arg0: string, txDetails?: Truffle.TransactionDetails): Promise<
        Truffle.TransactionResponse<AllEvents>
      >;
      call(arg0: string, txDetails?: Truffle.TransactionDetails): Promise<void>;
      sendTransaction(
        arg0: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        arg0: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    setFeeToSetter: {
      (arg0: string, txDetails?: Truffle.TransactionDetails): Promise<
        Truffle.TransactionResponse<AllEvents>
      >;
      call(arg0: string, txDetails?: Truffle.TransactionDetails): Promise<void>;
      sendTransaction(
        arg0: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        arg0: string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };
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
