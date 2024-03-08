#include "std.zh"
#include "TypeAString.zh"
#include "Archipelago.zh"
#include "EmilyMisc.zh"
#includepath "../../../ScriptBank"
#includepath "../../../ScriptBank/AP"
using namespace Emily;

global script onLaunch
{
	CONFIG FONT = FONT_Z1;
	CONFIG MID_Y = 56;
	CONFIG TILE_PTR = 14;
	CONFIG PTR_WID = 10;
	CONFIG PTR_HEI = 8;
	bool first_launch = true;
	bool archipelago_mode = false;

	int cache_player_id, cache_player_team;
	char32 cache_seed[1], cache_slot[1];
	void run()
	{
		const int real_fh = Text->FontHeight(FONT);
		const int fh = real_fh+4;
		const int Y1 = MID_Y - 1*fh;
		char32 b1[] = "Start";
		char32 b2[] = "Start AP Randomizer";
		char32 bufs[] = {b1,b2};
		const int NUM_OPTS = 2;
		int sel = 0;
		bool end = false;
		if(first_launch)
		{
			loop()
			{
				until(end)
				{
					ColorScreen(7, 0x0F, true);
					for(int q = 0; q < 2; ++q)
					{
						int wid = Text->StringWidth(bufs[q], FONT);
						Screen->DrawString(7, 128, Y1+q*fh+2, FONT, 0x01, -1, TF_CENTERED, bufs[q]);
						if(q == sel)
							Screen->FastTile(7, 128-wid/2-PTR_WID,(Y1+q*fh+2)+(real_fh-PTR_HEI)/2, TILE_PTR, 0);
					}
					if(Input->KeyPress[KEY_UP])
					{
						if(sel)
							--sel;
						else sel = NUM_OPTS-1;
					}
					else if(Input->KeyPress[KEY_DOWN])
					{
						if(sel < NUM_OPTS-1)
							++sel;
						else sel = 0;
					}
					else if(Input->KeyPress[KEY_ENTER])
						end = true;
					Waitframe();
				}
				switch(sel)
				{
					case 0:
						//start normally
						break 2;
					case 1:
						//start Archipelago
						if(int scr = CheckGenericScript("AP_Connect_Menu"))
						{
							RunGenericScriptFrz(scr, {0});
							if(Archipelago::status == Archipelago::STATUS_AUTHENTICATED)
							{
								archipelago_mode = true;
								//Store seed/slot identifying info, for validation on reconnects
								cache_player_id = Archipelago::player_id;
								cache_player_team = Archipelago::player_team;
								sprintf(cache_seed, "%s", Archipelago::seed);
								sprintf(cache_slot, "%s", Archipelago::slot);

								int locs[0];
								ResizeArray(locs,Archipelago::num_locs);
								loop(q : 0=..Archipelago::num_locs)
									locs[q] = q;
								//Archipelago::send_location_scouts_arr(1,locs); //WHY DOES THIS HARD FREEZE ZC??
								break 2;
							}
						}
						printf("Archipelago could not be launched!\n");
						break;
				}
			}
		}
		else if(archipelago_mode)
		{
			if(int scr = CheckGenericScript("AP_Connect_Menu"))
			{
				char32 ip[1], port[1], slot[1];
				sprintf(ip, "%s", Archipelago::ip);
				sprintf(port, "%s", Archipelago::port);
				sprintf(slot, "%s", Archipelago::slot);
				int sel = 4;
				loop()
				{
					RunGenericScriptFrz(scr,{sel});
					if(Archipelago::status == Archipelago::STATUS_AUTHENTICATED)
					{
						if(cache_player_id != Archipelago::player_id)
							printf("WRONG SLOT: Player ID %d mismatches %d\n",Archipelago::player_id,cache_player_id);
						else if(cache_player_team != Archipelago::player_team)
							printf("WRONG SLOT: Player Team %d mismatches %d\n",Archipelago::player_team,cache_player_team);
						else if(strcmp(cache_slot,Archipelago::slot))
							printf("WRONG SLOT: Slot Name '%s' mismatches '%s'\n",Archipelago::slot,cache_slot);
						else if(strcmp(cache_seed,Archipelago::seed))
							printf("WRONG SLOT: Seed mismatches\n");
						else break;
						printf("Please correct your connection information and try again!"
							" If you are trying to connect to a new seed, create a new save file!\n");
						sprintf(Archipelago::ip, "%s", ip);
						sprintf(Archipelago::port, "%s", port);
						sprintf(Archipelago::slot, "%s", slot);
						sel = 0;
					}
					else
					{
						printf("Archipelago could not be launched!\n");
					}
				}
			}
		}
		first_launch = false;
	}
}

generic script AP_Connect_Menu
{
	CONFIG FONT = FONT_Z1;
	CONFIG MID_Y = 56;
	void run(int cursor)
	{
		unless(CheckGenericScript("APConnect"))
		{
			printf("'APConnect' script missing from slot! Cannot proceed with connection menu!\n");
			return;
		}
		using namespace TypeAString;
		setEnterEndsTyping(true);
		setAllowBackspaceDelete(true);
		setOverflowWraps(false);

		char32 ip[] = "archipelago.gg";
		char32 port[] = "38281";
		char32 slot[] = "";
		char32 pwd[] = "";
		if(Archipelago::ip[0])
			sprintf(ip,"%s",Archipelago::ip);
		if(Archipelago::port[0])
			sprintf(port,"%s",Archipelago::port);
		if(Archipelago::slot[0])
			sprintf(slot,"%s",Archipelago::slot);
		//*
		sprintf(ip, "localhost");
		sprintf(port, "38281");
		sprintf(slot, "Player1");
		//*/
		char32 bufs[] = {ip, port, slot, pwd};
		char32 lbl1[] = "IP:";
		char32 lbl2[] = "Port:";
		char32 lbl3[] = "Slot:";
		char32 lbl4[] = "Passwd:";
		char32 lbls[] = {lbl1,lbl2, lbl3, lbl4};

		const int real_fh = Text->FontHeight(FONT);
		const int fh = real_fh+4;
		const int Y1 = MID_Y - 2.5*fh;
		const int minw = 96;
		const int NUM_OPTS = 5;
		int blinktimer = 0;
		const int BLINKRATE = 16;
		if(cursor < 0 || cursor > 4)
			cursor = 0;
		do
		{
			bool end = false;
			until(end)
			{
				endTypingMode();
				bool typing = cursor < 4;
				if(typing)
				{
					startTypingMode(cursor == 1 ? 5 : 99, TMODE_ALPHANUMERIC_SYMBOLS);
					setType(bufs[cursor]);
				}

				bool shifted = false;
				int wids[4];
				int mwid = 0;
				for(int q = 0; q < 4; ++q)
				{
					wids[q] = Text->StringWidth(bufs[q], FONT);
					mwid = Max(mwid, wids[q]);
				}
				do
				{
					ColorScreen(7, 0x0F, true);
					if(typing)
					{
						handleTyping();
						getType(bufs[cursor]);

						mwid = 0;
						wids[cursor] = Text->StringWidth(bufs[cursor], FONT);
						for(int q = 0; q < 4; ++q)
							mwid = Max(mwid, wids[q]);
					}
					blinktimer = (blinktimer+1) % (BLINKRATE*2);
					for(int q = 0; q < 4; ++q)
					{
						Screen->Rectangle(7, 128-Max(mwid/2, minw/2), Y1+q*fh, 128+Max(mwid/2, minw/2), Y1+((q+1)*fh)-2, 0x01);
						Screen->DrawString(7, 128, Y1+q*fh+2, FONT, 0x0F, -1, TF_CENTERED, bufs[q]);
						Screen->DrawString(7,128-Max(mwid/2, minw/2)-2, Y1+q*fh+2, FONT, 0x01, -1, TF_RIGHT, lbls[q]);
						if(cursor == q && blinktimer < BLINKRATE)
						{
							char32 tmp[0];
							int indx = __getTvar(TVAR_INDEX);
							sprintf(tmp, "%s", bufs[cursor]);
							tmp[indx] = 0;
							int x = 128-wids[cursor]/2;
							int w2 = Text->StringWidth(tmp, FONT);
							Screen->Rectangle(7, x+w2, Y1+q*fh+2, x+w2+3, Y1+q*fh + (fh-4), 0x02);
						}
					}
					//Draw connect button
					{
						char32 tmp[] = "Connect";
						Screen->Rectangle(7, 128-Max(mwid/2, minw/2), Y1+4*fh, 128+Max(mwid/2, minw/2), Y1+((4+1)*fh)-2, cursor==4 ? 0x02 : 0x01);
						Screen->DrawString(7, 128, Y1+4*fh+2, FONT, 0x0F, -1, TF_CENTERED, tmp);
					}
					if(end)
						break;
					
					if(Input->KeyPress[KEY_UP])
					{
						if(cursor)
							--cursor;
						else cursor = NUM_OPTS-1;
						shifted = true;
					}
					else if(Input->KeyPress[KEY_DOWN] || (cursor < NUM_OPTS-1) && Input->KeyPress[KEY_ENTER])
					{
						if(cursor < NUM_OPTS-1)
							++cursor;
						else cursor = 0;
						shifted = true;
					}
					else if(cursor == 4 && Input->KeyPress[KEY_ENTER])
						end = true;
					Waitframe();
				} until(shifted && !end);
			}
			char32 buf[1];
			sprintf(buf,"CONNECTING... %c TO CANCEL",Archipelago::quitchar());
			Screen->DrawString(7, 128, Y1+5*fh+2, FONT, 0x01, -1, TF_CENTERED, buf);
			Waitframe();
		} until(Archipelago::ap_connect(ip, port, slot, pwd));

		char32 wait_msg[] = "Connecting; please wait...";
		ColorScreen(7, 0x0F, true);
		Emily::DrawStrings(7, 128, MID_Y, FONT, 0x01, -1, TF_CENTERED, wait_msg, OP_OPAQUE, 2, 256);

		if(int scr = CheckGenericScript("APHandler"))
		{
			auto gd = RunGenericScriptFrz(scr, {true});
			gd->InitD[0] = false;
		}
		while(Archipelago::status == Archipelago::STATUS_CONNECTING
			|| Archipelago::status == Archipelago::STATUS_CONNECTED)
		{
			Waitframe();
		}
	}
}



bool ignore_next_location_scout = false;
namespace Archipelago::Settings
{
    void ap_get_game(char32 buf) //Return your game name
    {
        sprintf(buf, "ZQC LGA3 Remastered");
    }
    long items_handling() //return your item handling mode
    {
        return 101Lb;
    }
    void add_tags(JSONRef ref) //Add your tags
    {
        ref->add_indx_str("ZQuest Classic");
    }
    void on_room_info(JSONRef ref)
    {
        //https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#RoomInfo
		
    }
    void on_connected(JSONRef ref)
    {
        //https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#Connected
		ref->sub_find({NULL,{"slot_data"}});
		ref->print();
    }
    void on_item_received(NetworkItem itm, int total_count)
    {
        //itemlist is a SINGLE NetworkItem, which has been sent to the player
        //total_count is how many of this item you now own in total
        //'mark_item_collected()' is already called for you for this item, just before this.
    }
    void on_location_scouts(NetworkItem itemlist)
    {
        //itemlist is an ARRAY of NetworkItems, responding to a LocationScouts request
    }
    void on_room_update(JSONRef ref)
    {
        //https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#RoomUpdate

    }
    bool on_print_json(JSONRef ref)
    {
        //https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#PrintJSON
        //Return true to log the text to the console, false to ignore it.
        return true;
    }
    void on_bounced(JSONRef ref)
    {
        //https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#Bounced
        
    }
    void on_retrieved(JSONRef ref)
    {
        //https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#Retrieved
        
    }
    void on_set_reply(JSONRef ref)
    {
        //https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#SetReply
        
    }
    void do_remove_location(int id)
    {
        //forcibly mark this location as "already collected"
        
    }
}
