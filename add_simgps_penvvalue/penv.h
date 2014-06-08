/******************************************************
 * $Id$
 *
 * Copyright (C) 1999 Ricoh Company, Ltd.  All Rights Reserved.
 *
 *   FILE NAME       : penv.h
 *   VERSION         : $Revision$
 *   AUTHOR          : SHINDOH Nobuhiro
 *-----------------------------------------------------
 *       HISTORY
 *	 shindoh - 18 Oct 1999: Created.
 *	 $Log$
 *	
 ******************************************************/
#ifndef _GPS_PENV_H_
#define	_GPS_PENV_H_

#define	GPS_PENV_NAME_COMMON		"COMMON"
#define	GPS_PENV_NAME_PCL		"PCL"
#define	GPS_PENV_NAME_POSTSCRIPT	"POSTSCRIPT"

#define	GPS_PENV_VARFLAG_READONLY	(1 << 0)	/* READ ONLY */
#define	GPS_PENV_VARFLAG_NV		(1 << 1)	/* NVRAM SAVE */
#define	GPS_PENV_VARFLAG_PANELONLY	(1 << 2)	/* PANEL ONLY */
#define	GPS_PENV_VARFLAG_SAVE_NV	(1 << 3)	/* SAVE TO PRINTERNV */
#define	GPS_PENV_VARFLAG_SAVE_SP	(1 << 4)	/* SAVE TO SP */
#define	GPS_PENV_VARFLAG_DEST_DOM	(1 << 5)	/* DOM ONLY */
#define	GPS_PENV_VARFLAG_DEST_EXP	(1 << 6)	/* EXP ONLY */
#define	GPS_PENV_VARFLAG_DEST_NA	(1 << 7)	/* NA ONLY */
#define	GPS_PENV_VARFLAG_DEST_EU	(1 << 8)	/* EU ONLY */
#define	GPS_PENV_VARFLAG_DHCP		(1 << 9)	/* DHCP */
#define	GPS_PENV_VARFLAG_NOT_RESET	(1 << 10)	/* NOT RESET */
#define	GPS_PENV_VARFLAG_MODIFIED	(1 << 30)	/* modified */
#define	GPS_PENV_VARFLAG_INVALID	(1 << 31)	/* invalid */

#define	GPS_PENV_VALTYPE_ENUM		0		/* ENUMERATE */
#define	GPS_PENV_VALTYPE_INT		1		/* INT */
#define	GPS_PENV_VALTYPE_FLOAT		2		/* FLOAT */
#define	GPS_PENV_VALTYPE_NETADDR	3		/* network address */
#define	GPS_PENV_VALTYPE_STR		4		/* STRING */

typedef struct gps_penv_varinfo {
	long			id;		/* variable ID */
	unsigned long		flag;		/* variable flag */
	long			init_val;	/* initial value */
	long			def_val;	/* default value */
	long			cur_val;	/* current value */
	unsigned char		val_denom;	/* value denominator */
	unsigned char		val_type;	/* value type */
	long			val_num;	/* number of value list */
} gps_penv_varinfo_t;

/*
 *	PENV ERROR CODE
 */
#define	GPS_PENV_ERR_FATAL		(-1)
#define	GPS_PENV_ERR_BUSY		(-2)
#define	GPS_PENV_ERR_NOTABLE		(-3)
#define	GPS_PENV_ERR_NOVAR		(-4)
#define	GPS_PENV_ERR_READONLY		(-5)
#define	GPS_PENV_ERR_VALUE		(-6)
#define	GPS_PENV_ERR_NOSTR		(-7)
#endif /* !_GPS_PENV_H_ */
/*
 * Copyright (c) 1999 Ricoh Company, Ltd.  All Rights Reserved.
 */
