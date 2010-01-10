/*
* Copyright (C) 2009 Mamadou Diop.
*
* Contact: Mamadou Diop <diopmamadou@yahoo.fr>
*	
* This file is part of Open Source Doubango Framework.
*
* DOUBANGO is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*	
* DOUBANGO is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Lesser General Public License for more details.
*	
* You should have received a copy of the GNU General Public License
* along with DOUBANGO.
*
*/

/**@file tsip_header_P_Preferred_Identity.c
 * @brief SIP P-Preferred-Identity header as per RFC 3325.
 *     Header field         where   proxy   ACK  BYE  CAN  INV  OPT  REG
 *     ------------         -----   -----   ---  ---  ---  ---  ---  ---
 *     P-Preferred-Identity          adr     -    o    -    o    o    -
 *
 *
 *                                          SUB  NOT  REF  INF  UPD  PRA
 *                                          ---  ---  ---  ---  ---  ---
 *                                           o    o    o    -    -    -
 *
 * @author Mamadou Diop <diopmamadou(at)yahoo.fr>
 *
 * @date Created: Sat Nov 8 16:54:58 2009 mdiop
 */
#include "tinysip/headers/tsip_header_P_Preferred_Identity.h"

#include "tinysip/parsers/tsip_parser_uri.h"

#include "tsk_debug.h"
#include "tsk_memory.h"

/**@defgroup tsip_header_P_Preferred_Identity_group SIP P_Preferred_Identity header.
*/

/***********************************
*	Ragel state machine.
*/
%%{
	machine tsip_machine_parser_header_P_Preferred_Identity;

	# Includes
	include tsip_machine_utils "./tsip_machine_utils.rl";
	
	action tag
	{
		tag_start = p;
	}
	
	action parse_uri
	{	
		if(!hdr_pi->uri) /* Only one URI */
		{
			int len = (int)(p  - tag_start);
			hdr_pi->uri = tsip_uri_parse(tag_start, (size_t)len);
		}
	}

	action parse_display_name
	{
		if(!hdr_pi->display_name)
		{
			PARSER_SET_STRING(hdr_pi->display_name);
		}

	}

	action eob
	{
	}
	
	#/* FIXME: Only one URI is added --> According to the ABNF the header could have more than one URI. */
	
	URI = (scheme HCOLON any+)>tag %parse_uri;
	display_name = (( token LWS )+ | quoted_string)>tag %parse_display_name;
	my_name_addr = display_name? :>LAQUOT<: URI :>RAQUOT;

	PPreferredID_value = (my_name_addr)>0 | (URI)>1;
	PPreferredID = "P-Preferred-Identity"i HCOLON PPreferredID_value>1 ( COMMA PPreferredID_value )*>0;
	
	# Entry point
	main := PPreferredID :>CRLF @eob;

}%%

int tsip_header_Preferred_Identity_tostring(const void* header, tsk_buffer_t* output)
{
	if(header)
	{
		int ret;
		const tsip_header_P_Preferred_Identity_t *P_Preferred_Identity = header;

		if(ret=tsip_uri_tostring(P_Preferred_Identity->uri, 1, 1, output))
		{
			return ret;
		}
	}
	return -1;
}

tsip_header_P_Preferred_Identity_t *tsip_header_P_Preferred_Identity_parse(const char *data, size_t size)
{
	int cs = 0;
	const char *p = data;
	const char *pe = p + size;
	const char *eof = pe;
	tsip_header_P_Preferred_Identity_t *hdr_pi = TSIP_HEADER_P_PREFERRED_IDENTITY_CREATE();
	
	const char *tag_start;

	%%write data;
	%%write init;
	%%write exec;
	
	if( cs < %%{ write first_final; }%% )
	{
		TSIP_HEADER_P_PREFERRED_IDENTITY_SAFE_FREE(hdr_pi);
	}
	
	return hdr_pi;
}







//========================================================
//	P_Preferred_Identity header object definition
//

/**@ingroup tsip_header_P_Preferred_Identity_group
*/
static void* tsip_header_P_Preferred_Identity_create(void *self, va_list * app)
{
	tsip_header_P_Preferred_Identity_t *P_Preferred_Identity = self;
	if(P_Preferred_Identity)
	{
		TSIP_HEADER(P_Preferred_Identity)->type = tsip_htype_P_Preferred_Identity;
		TSIP_HEADER(P_Preferred_Identity)->tostring = tsip_header_Preferred_Identity_tostring;
	}
	else
	{
		TSK_DEBUG_ERROR("Failed to create new P_Preferred_Identity header.");
	}
	return self;
}

/**@ingroup tsip_header_P_Preferred_Identity_group
*/
static void* tsip_header_P_Preferred_Identity_destroy(void *self)
{
	tsip_header_P_Preferred_Identity_t *P_Preferred_Identity = self;
	if(P_Preferred_Identity)
	{
		TSK_FREE(P_Preferred_Identity->display_name);
		TSIP_URI_SAFE_FREE(P_Preferred_Identity->uri);
	}
	else TSK_DEBUG_ERROR("Null P_Preferred_Identity header.");

	return self;
}

static const tsk_object_def_t tsip_header_P_Preferred_Identity_def_s = 
{
	sizeof(tsip_header_P_Preferred_Identity_t),
	tsip_header_P_Preferred_Identity_create,
	tsip_header_P_Preferred_Identity_destroy,
	0
};
const void *tsip_header_P_Preferred_Identity_def_t = &tsip_header_P_Preferred_Identity_def_s;