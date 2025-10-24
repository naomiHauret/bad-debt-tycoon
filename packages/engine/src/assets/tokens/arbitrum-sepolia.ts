/* Generated file - do not edit manually */
import usdc from './whitelist/usdc/definition.json';
import pyusd from './whitelist/pyusd/definition.json';

export const TOKEN_LIST = [
  {
    id: usdc.id,
    name: usdc.name,
    symbol: usdc.symbol,
    decimals: usdc.decimals,
    address: usdc.deployment["421614"]
  },
  {
    id: pyusd.id,
    name: pyusd.name,
    symbol: pyusd.symbol,
    decimals: pyusd.decimals,
    address: pyusd.deployment["421614"]
  }
] as const;
