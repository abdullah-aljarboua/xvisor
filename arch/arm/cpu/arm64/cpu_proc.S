/**
 * Copyright (c) 2013 Sukanto Ghosh.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 * @file cpu_proc.S
 * @author Sukanto Ghosh (sukantoghosh@gmail.com)
 * @author Anup Patel (anup@brainfault.org)
 * @brief Low-level implementation of ARMv7 with virtualization extension
 * specific quirky functions
 */

#include <cpu_defines.h>

/*
 *	Boot-time processor setup
 *
 *	Initialise TLB, Caches, and MMU state ready to switch the MMU
 *	on.  Return in x0 the new SCTLR_EL2 control register setting.
 *
 *	This should cover all ARMv8 with virtualization extension cores.
 *
 *	Note: We blindly use all registers because this will be
 *	called at boot-time when there is not stack
 */
	.globl proc_setup
proc_setup:
	ic	iallu				/* I+BTB cache invalidate */
	tlbi	alle2is				/* invalidate I + D TLBs */
	dsb	sy

	adr	x5, v8_crval
	ldr	x6, [x5, #0]
	ldr	x7, [x5, #8]
   	mrs 	x0, sctlr_el2			/* read control register */
	bic	x0, x0, x6			/* clear bits them */
	orr	x0, x0, x7			/* set them */
	ret

	/*                W
	 *        E       X                   S
	 * .... ..E. .... N... ...I .... .... ACAM
	 * 0000 00x0 0000 x000 000x 0000 0000 xxxx < forced
	 *                0       1           0101 < we want
	 */
	.align	3
	.type	v8_crval, #object
v8_crval:
	.dword	0x0008000A /* clear */
	.dword	0x00001005 /* mmuset */

#ifdef CONFIG_SMP
	/* 
	 * Retrive SMP ID of current processor
	 */
	.globl arch_smp_id
arch_smp_id:
	mrs	x0, tpidr_el2
	ret

	/* 
	 * Setup SMP ID of current processor
	 */
	.globl proc_setup_smp_id
proc_setup_smp_id:
	/* Ensure that next SMP ID in x0
	 * is less than CONFIG_CPU_COUNT
	 */
	ldr	x1, =CONFIG_CPU_COUNT
	cmp	x0, x1
	blt	proc_setup_smp_id_done
	b	.

proc_setup_smp_id_done:
	msr	tpidr_el2, x0
	ret
#endif
