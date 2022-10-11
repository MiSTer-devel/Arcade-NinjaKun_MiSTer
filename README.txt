---------------------------------------------------------------------------------
-- 
-- Arcade: Ninja-Kun  port to MiSTer by MiSTer-X
-- 23 October 2019
-- https://github.com/MrX-8B/MiSTer-Arcade-NinjaKun
-- 
-- Added support for Raiders5, Nova 2001 from MiST by Mike S
---------------------------------------------------------------------------------
-- FPGA Ninja-Kun for Spartan-6
------------------------------------------------
-- Copyright (c) 2011 MiSTer-X
---------------------------------------------------------------------------------
-- T80/T80s - Version : 0242
-----------------------------
-- Z80 compatible microprocessor core
-- Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org)
---------------------------------------------------------------------------------
-- YM2149 (AY-3-8910)
-- Copyright (c) MikeJ - Jan 2005
---------------------------------------------------------------------------------
-- 
-- 
-- Keyboard inputs :
--
--   F2          : Coin + Start 2 players
--   F1          : Coin + Start 1 player
--   UP,DOWN,LEFT,RIGHT arrows : Movements
--   SPACE       : Shot
--   CTRL        : Jump
--
-- MAME/IPAC/JPAC Style Keyboard inputs:
--   5           : Coin 1
--   6           : Coin 2
--   1           : Start 1 Player
--   2           : Start 2 Players
--   R,F,D,G     : Player 2 Movements
--   A           : Player 2 Shot
--   S           : Player 2 Jump
--
-- Joystick support.
--
--
---------------------------------------------------------------------------------

                                *** Attention ***

ROMs are not included. In order to use this arcade, you need to provide the
correct ROMs.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for
information on how to setup and use the environment.

Quickreference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/_Arcade/mame/<mame rom>.zip
/_Arcade/hbmame/<hbmame rom>.zip

Note for Nova 2001 (From Mame)

- nova2001 is very sensitive to coin inputs, if the coin isn't held down long
  enough, or is held down too long the game will reset, likewise if coins are
  inserted too quickly. This only happens in nova2001 and not in nova2001u.
  (the nova2001h set seems to be an unofficial fix for this issue, presumably
   it's so sensitive it would reset sometimes in the original cabinet?)
- nova2001h MRA was added to address the original cabinet issue.


