/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import BN from "bn.js";
import { EventData, PastEventOptions } from "web3-eth-contract";

export interface ERC20DetailedContract
  extends Truffle.Contract<ERC20DetailedInstance> {
  "new"(
    name: string,
    symbol: string,
    decimals: number | BN | string,
    meta?: Truffle.TransactionDetails
  ): Promise<ERC20DetailedInstance>;
}

type AllEvents = never;

export interface ERC20DetailedInstance extends Truffle.ContractInstance {
  /**
   * @returns the name of the token.
   */
  name(txDetails?: Truffle.TransactionDetails): Promise<string>;

  /**
   * @returns the symbol of the token.
   */
  symbol(txDetails?: Truffle.TransactionDetails): Promise<string>;

  /**
   * @returns the number of decimals of the token.
   */
  decimals(txDetails?: Truffle.TransactionDetails): Promise<BN>;

  methods: {
    /**
     * @returns the name of the token.
     */
    name(txDetails?: Truffle.TransactionDetails): Promise<string>;

    /**
     * @returns the symbol of the token.
     */
    symbol(txDetails?: Truffle.TransactionDetails): Promise<string>;

    /**
     * @returns the number of decimals of the token.
     */
    decimals(txDetails?: Truffle.TransactionDetails): Promise<BN>;
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
