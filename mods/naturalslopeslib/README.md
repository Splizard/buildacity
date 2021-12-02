Natural slopes library
======================

* Version 1.3
* With thanks to all modders, mainly from the stairs mod for study.

This mod add the ability for nodes to turn into slopes and back to full block
shape by themselves according to the surroundings and the material hardness. It creates
more natural looking landscapes and smoothes movements by removing some edges.

Slopes can be generated in various ways. Those events can be turned on or off in
settings. The shape is updated on generation, with time, by stepping on edges or
when digging and placing nodes.

As Minetest main unit is the block, having half-sized blocks can break a lot of things.
Thus half-blocks like slopes are still considered as a single block. A single slope
can turn back to a full node and vice-versa and half-blocks are not considered
buildable upon (they will transform back into full block).

See naturalslopeslib_api.txt for the documentation of the API.

## Dependencies

None, this is a standalone library for other mods to build upon. It doesn't
have any effect by itself.

## Optional dependencies:

* poschangelib: to enable shape update when walking on nodes
* twmlib: to enable update from time to time

## Source code

* Written by Karamel
* Licenced under LGPLv2 or, at your discretion, any later version.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 2.1 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

https://www.gnu.org/licenses/licenses.html#LGPL

## Media

* Models licensed under CC-0.