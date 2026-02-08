# ERC-4626 Solution Walkthrough

This walkthrough explains the reference implementation in `src/solution/ERC4626VaultSolution.sol` step by step.

## 1. What This Vault Does

The vault accepts an underlying ERC20 asset and mints ERC20 share tokens.

- `assets` are the deposited token units (for example USDC or WETH).
- `shares` are proportional ownership claims on vault assets.
- Share price is implied by `totalAssets / totalSupply`.

Why this exists: ERC-4626 standardizes vault APIs so protocols and wallets can integrate without custom adapters.

## 2. Storage Model (EVM View)

The contract stores:

- `asset`: underlying token contract address.
- `totalSupply`, `balanceOf`, `allowance`: share-token state.
- `_totalAssets`: internal accounting for managed assets.
- `_locked`: reentrancy guard state.

EVM effects:

- Deposits/mints write `_totalAssets`, `totalSupply`, and share balances.
- Withdraw/redeem writes burn share balances and reduce `_totalAssets`.
- Allowance writes happen on `approve` and delegated withdraw/redeem.

## 3. ERC20 Share Layer

`transfer`, `approve`, and `transferFrom` implement basic ERC20 behavior for shares.

Why this matters: shares are meant to be composable in other DeFi contracts, not just held by the depositor.

## 4. Core Vault Flows

## 4.1 `deposit(assets, receiver)`

What it does:

1. Validates input (`receiver != 0`, `assets > 0`).
2. Computes `shares = convertToShares(assets)` (round down).
3. Pulls assets via `asset.transferFrom`.
4. Updates `_totalAssets`.
5. Mints shares.
6. Emits `Deposit`.

Why this order:

- Vault never mints shares before the ERC20 transfer succeeds.
- Accounting only updates after assets arrive.

EVM effects:

- External call: `transferFrom`.
- Storage writes: `_totalAssets`, `totalSupply`, `balanceOf[receiver]`.
- Log: `Deposit` and ERC20 `Transfer` (mint).

## 4.2 `mint(shares, receiver)`

What it does:

1. Validates input (`receiver != 0`, `shares > 0`).
2. Computes required assets with `previewMint` (round up).
3. Pulls those assets.
4. Updates `_totalAssets`.
5. Mints exact shares.
6. Emits `Deposit`.

Why this exists: user asks for exact shares, so asset requirement must be conservative (round up).

## 4.3 `withdraw(assets, receiver, owner)`

What it does:

1. Validates input.
2. Computes shares to burn with `previewWithdraw` (round up).
3. Enforces allowance if caller is not `owner`.
4. Burns shares.
5. Decrements `_totalAssets`.
6. Transfers assets out.
7. Emits `Withdraw`.

Why this order is safer:

- Burn and accounting reduction happen before external asset transfer.
- If an interaction path is abused, state is already in a conservative post-withdraw form.

## 4.4 `redeem(shares, receiver, owner)`

What it does:

1. Validates input.
2. Computes `assets = convertToAssets(shares)` (round down).
3. Enforces allowance when needed.
4. Burns exact shares.
5. Decrements `_totalAssets`.
6. Transfers assets out.
7. Emits `Withdraw`.

Why rounding differs from `withdraw`:

- Redeem takes exact shares in, so output assets are rounded down.
- Withdraw targets exact assets out, so required shares are rounded up.

## 5. Preview and Conversion Functions

Read-only conversion helpers must align with state-changing paths:

- `previewDeposit` mirrors `deposit` conversion.
- `previewMint` mirrors `mint` required assets.
- `previewWithdraw` mirrors `withdraw` required shares.
- `previewRedeem` mirrors `redeem` output assets.

If these drift, frontends quote wrong values and integrations break.

## 6. Common ERC-4626 Misconceptions

## 6.1 "Rounding is minor, so any direction is fine"

Incorrect. Rounding direction is a security choice:

- Round down when returning output to user.
- Round up when computing user-required input.

This prevents incremental value leakage from vault to attacker.

## 6.2 "Use raw token balance as `totalAssets`"

Risky. Direct token donations can manipulate perceived asset totals.

Internal accounting (`_totalAssets`) makes the vault's math explicit and resistant to unsolicited transfers.

## 6.3 "First depositor is trivial"

Not always. Initial exchange-rate setup is a known attack surface (inflation-style manipulation).

The reference implementation explicitly handles `totalSupply == 0` as 1:1 bootstrap logic.

## 7. Event Semantics

- `Deposit(sender, owner, assets, shares)` records asset-in and share-out.
- `Withdraw(sender, receiver, owner, assets, shares)` records share-in and asset-out.

These are essential for off-chain accounting, analytics, and debugging.
