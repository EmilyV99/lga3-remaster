#include "std.zh"
#include "std_zh/std_extension.zh"
#include "TypeAString.zh"
#include "Archipelago.zh"
#include "EmilyMisc.zh"
#includepath "../../../ScriptBank"
#includepath "../../../ScriptBank/AP"
using namespace Emily;

CONFIG AP_HOLDUP_ITEM = 254;
CONFIG SFX_JINGLE = 20;
CONFIG AP_DUMMY_COMBO_START = 65024;
CONFIG AP_DUMMY_START = 240;
CONFIG AP_DUMMY_COUNT = 4;
bool first_launch = true;
bool archipelago_mode = false;
bool is_easier_grinding = false;
global script onLaunch
{
	CONFIG FONT = FONT_Z1;
	CONFIG MID_Y = 56;
	CONFIG TILE_PTR = 14;
	CONFIG PTR_WID = 10;
	CONFIG PTR_HEI = 8;

	int cache_player_id, cache_player_team;
	char32 cache_seed[1], cache_slot[1];
	void run()
	{
		Game->FFRules[qr_TRACESCRIPTIDS] = Archipelago::AP_DEV_LOG;
		const int real_fh = Text->FontHeight(FONT);
		const int fh = real_fh+4;
		const int Y1 = MID_Y - 1*fh;
		char32 b1[] = "Start";
		char32 b2[] = "Start AP Randomizer";
		char32 bufs[] = {b1,b2};
		const int NUM_OPTS = 2;
		int sel = 0;
		bool end = false;

		is_easier_grinding = false;

		Waitframe();
		if(first_launch)
		{
			while(true)
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
							if(Archipelago::status >= Archipelago::STATUS_AUTHENTICATED)
							{
								archipelago_mode = true;
								//Store seed/slot identifying info, for validation on reconnects
								cache_player_id = Archipelago::ap_player_id;
								cache_player_team = Archipelago::ap_player_team;
								sprintf(cache_seed, "%s", Archipelago::seed);
								sprintf(cache_slot, "%s", Archipelago::slot);
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
				while(true)
				{
					RunGenericScriptFrz(scr,{sel});
					if(Archipelago::status >= Archipelago::STATUS_AUTHENTICATED)
					{
						if(cache_player_id != Archipelago::ap_player_id)
							printf("WRONG SLOT: Player ID %d mismatches %d\n",Archipelago::ap_player_id,cache_player_id);
						else if(cache_player_team != Archipelago::ap_player_team)
							printf("WRONG SLOT: Player Team %d mismatches %d\n",Archipelago::ap_player_team,cache_player_team);
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
					Archipelago::disconnect_socket();
				}
			}
		}
		if(archipelago_mode)
		{
			Waitframe();
			Screen->DrawString(7,128,56, FONT, 0x01, -1, TF_CENTERED, "CONNECTED! LOADING...");
			Waitframe();
			handle_ap_placements();
		}
		first_launch = false;
	}
}
global script Active
{
	void load_gdatas(genericdata arr, char32 name_arr)
	{
		for(name : name_arr)
		{
			if(int scr = CheckGenericScript(name))
				if(auto gd = RunGenericScript(scr))
					ArrayPushBack(arr, gd);
		}
	}
	void run()
	{
		until(archipelago_mode)
			Waitframe();
		if(int scr = CheckGenericScript("AP_Pickup_Runner"))
			RunGenericScript(scr);
		if(int scr = CheckGenericScript("AP_ScreenChange_Runner"))
			RunGenericScript(scr);
		if(int scr = CheckGenericScript("AP_ItemCollect_Handler"))
			RunGenericScript(scr);
		while(true)
		{
			Waitframe();
		}
	}
}

void set_easier_grinding()
{
	if(is_easier_grinding) return;
	is_easier_grinding = true;
	dropsetdata dropsets[13];
	for(int q = 0; q < 13; ++q)
		dropsets[q] = Game->LoadDropset(q);
	//Default
	dropsets[1]->Items[1] = 39; //10r -> 50r
	dropsets[1]->Items[2] = 38; //5r -> 20r
	dropsets[1]->Items[5] = 86; //1r -> 10r
	dropsets[1]->Chances[1] *= 4;
	dropsets[1]->Chances[2] *= 4;
	dropsets[1]->Chances[5] *= 4;
	//Bombs
	dropsets[2]->Chances[6] *= 5; //Increase Super Bomb droprate
	//Money
	dropsets[3]->Items[1] = 86; //1r -> 10r
	dropsets[3]->Items[2] = 38; //5r -> 20r
	dropsets[3]->Items[3] = 39; //10r -> 50r
	dropsets[3]->Items[4] = 87; //20r -> 100r
	dropsets[3]->Chances[1] *= 4;
	dropsets[3]->Chances[2] *= 4;
	dropsets[3]->Chances[3] *= 4;
	dropsets[3]->Chances[4] *= 4;
	//Much Money
	dropsets[7]->Items[0] = 86; //1r -> 10r
	dropsets[7]->Items[1] = 38; //5r -> 20r
	dropsets[7]->Items[2] = 39; //10r -> 50r
	dropsets[7]->Items[3] = 87; //20r -> 100r
	dropsets[7]->Items[4] = 171; //50r -> 500r
	dropsets[7]->Chances[0] *= 4;
	dropsets[7]->Chances[1] *= 4;
	dropsets[7]->Chances[2] *= 4;
	dropsets[7]->Chances[3] *= 4;
	dropsets[7]->Chances[4] *= 4;
	//Everything
	dropsets[8]->Items[3] = 86; //1r -> 10r
	dropsets[8]->Items[4] = 38; //5r -> 20r
	dropsets[8]->Items[5] = 39; //20r -> 50r
	dropsets[8]->Items[6] = 87; //50r -> 100r
	dropsets[8]->Chances[3] *= 4;
	dropsets[8]->Chances[4] *= 4;
	dropsets[8]->Chances[5] *= 4;
	dropsets[8]->Chances[6] *= 4;
	//Bushes
	dropsets[12]->Items[3] = 38; //1r -> 20r
	dropsets[12]->Items[4] = 39; //5r -> 50r
	dropsets[12]->Items[5] = 87; //20r -> 100r
	dropsets[12]->Chances[3] *= 4;
	dropsets[12]->Chances[4] *= 4;
	dropsets[12]->Chances[5] *= 4;
}

void fill_bottle(int btype)
{
	int bottle_count = GetHighestLevelItemOwned(IC_BOTTLE);
	for(int q = 0; q < bottle_count; ++q)
	{
		unless(Game->BottleState[q])
		{
			Game->BottleState[q] = btype;
			return;
		}
	}
}

int refill_shops = 0;
int silent_get_item(Archipelago::NetworkItem itm, int number, char32 buf = NULL)
{
	#option STRING_SWITCH_CASE_INSENSITIVE on
	char32 b2[1];
	char32 ptr = buf ? buf : b2;
	ResizeArray(ptr,256);
	int pickup_id = -1, holdup_id = -1;
	if(number < 1) number = 1;
	switch(itm->item_name)
	{
		case "Nothing":
		{
			sprintf(ptr,"Nothing");
			break;
		}
		case "Progressive Sword":
		{
			switch(number)
			{
				case 1:
					pickup_id = 5;
					break;
				case 2:
					pickup_id = 6;
					break;
				case 3:
					pickup_id = 7;
					break;
				case 4: default:
					pickup_id = 36;
					break;
			}
			break;
		}
		case "Progressive Tunic":
		{
			switch(number)
			{
				case 1:
					pickup_id = 17;
					break;
				case 2:
					pickup_id = 18;
					break;
				case 3: default:
					pickup_id = 61;
					break;
			}
			break;
		}
		case "Progressive Bottle":
		{
			switch(number)
			{
				case 1:
					pickup_id = 145;
					break;
				case 2:
					pickup_id = 146;
					break;
				case 3:
					pickup_id = 147;
					break;
				case 4: default:
					pickup_id = 148;
					break;
			}
			unless(Hero->Item[167])
			{
				itemsprite spr = Screen->CreateItem(167);
				spr->ForceGrab = true;
				spr->PickupString = 0;
				spr->Pickup |= IP_HOLDUP;
				spr->NoSound = true;
			}
			break;
		}
		case "Progressive Jump":
		{
			switch(number)
			{
				case 1:
					pickup_id = 91;
					break;
				case 2: default:
					pickup_id = 158;
					break;
			}
			break;
		}
		case "Progressive Bomb Bag":
		{
			Hero->Item[143] = true; //'Bomb Bag: Menu', menu dummy item
			switch(number)
			{
				case 1:
					pickup_id = 81;
					break;
				case 2:
					pickup_id = 82;
					break;
				case 3: default:
					pickup_id = 83;
					break;
			}
			break;
		}
		case "Progressive Quiver":
		{
			switch(number)
			{
				case 1:
					pickup_id = 74;
					break;
				case 2:
					pickup_id = 75;
					break;
				case 3: default:
					pickup_id = 76;
					break;
			}
			break;
		}
		case "Progressive Magic Ring":
		{
			switch(number)
			{
				case 1:
					pickup_id = 115;
					break;
				case 2:
					pickup_id = 116;
					break;
				case 3:
					pickup_id = 117;
					break;
				case 4: default:
					pickup_id = 118;
					break;
			}
			break;
		}
		case "Progressive Life Ring":
		{
			switch(number)
			{
				case 1:
					pickup_id = 112;
					break;
				case 2:
					pickup_id = 113;
					break;
				case 3: default:
					pickup_id = 114;
					break;
			}
			break;
		}
		case "Progressive Charge Ring":
		{
			switch(number)
			{
				case 1:
					pickup_id = 101;
					break;
				case 2: default:
					pickup_id = 102;
					break;
			}
			break;
		}
		case "Progressive Shield":
		{
			switch(number)
			{
				case 1:
					pickup_id = 93;
					break;
				case 2:
					pickup_id = 8;
					break;
				case 3: default:
					pickup_id = 37;
					break;
			}
			break;
		}
		case "Progressive Boomerang":
		{
			switch(number)
			{
				case 1:
					pickup_id = 23;
					break;
				case 2:
					pickup_id = 24;
					break;
				case 3: default:
					pickup_id = 35;
					break;
			}
			break;
		}
		case "Progressive Lantern":
		{
			switch(number)
			{
				case 1:
					pickup_id = 10;
					break;
				case 2: default:
					pickup_id = 11;
					break;
			}
			break;
		}
		case "Progressive Wallet":
		{
			switch(number)
			{
				case 1:
					pickup_id = 41;
					break;
				case 2: default:
					pickup_id = 42;
					break;
			}
			break;
		}
		case "Progressive Coupon":
		{
			switch(number)
			{
				case 1:
					pickup_id = 109;
					break;
				case 2:
					pickup_id = 110;
					break;
				case 3: default:
					pickup_id = 111;
					break;
			}
			break;
		}
		case "Progressive Bracelet":
		{
			switch(number)
			{
				case 1:
					pickup_id = 19;
					break;
				case 2: default:
					pickup_id = 56;
					break;
			}
			break;
		}
		case "Progressive Hookshot":
		{
			switch(number)
			{
				case 1:
					pickup_id = 52;
					break;
				case 2: default:
					pickup_id = 89;
					break;
			}
			break;
		}
		case "Progressive Traction":
		{
			switch(number)
			{
				case 1:
					pickup_id = 154;
					break;
				case 2: default:
					pickup_id = 155;
					break;
			}
			break;
		}
		case "Progressive Arrows":
		{
			switch(number)
			{
				case 1:
					pickup_id = 13;
					break;
				case 2:
					pickup_id = 14;
					break;
				case 3: default:
					pickup_id = 57;
					break;
			}
			break;
		}
		case "Bow":
		{
			pickup_id = 15;
			break;
		}
		case "Wand":
		{
			pickup_id = 25;
			break;
		}
		case "Magic Book":
		{
			pickup_id = 32;
			break;
		}
		case "Hammer":
		{
			pickup_id = 54;
			break;
		}
		case "Magic Rock":
		{
			pickup_id = 169;
			break;
		}
		case "Divine Fire":
		{
			pickup_id = 64;
			break;
		}
		case "Divine Protection":
		{
			pickup_id = 66;
			break;
		}
		case "Divine Escape":
		{
			pickup_id = 65;
			break;
		}
		case "Flippers":
		{
			pickup_id = 51;
			break;
		}
		case "Ocarina":
		{
			pickup_id = 31;
			break;
		}
		case "Lens of Truth":
		{
			pickup_id = 53;
			break;
		}
		case "Cheese":
		{
			pickup_id = 16;
			break;
		}
		case "Scroll: Cross Beams":
		{
			pickup_id = 95;
			break;
		}
		case "Scroll: Peril Beam":
		{
			pickup_id = 103;
			break;
		}
		case "Scroll: Hurricane Spin":
		{
			pickup_id = 98;
			break;
		}
		case "Heart Container":
		{
			pickup_id = 28;
			break;
		}
		case "Magic Container":
		{
			pickup_id = 58;
			break;
		}
		case "Half Magic":
		{
			Game->Generic[GEN_MAGICDRAINRATE] = 1;
			holdup_id = 172;
			break;
		}
		case "Triforce Fragment":
		{
			Game->LItems[number] |= LI_TRIFORCE;
			holdup_id = 20;
			break;
		}
		case "Potion (Red)":
		{
			refill_shops |= 0001b;
			fill_bottle(1);
			holdup_id = 149;
			break;
		}
		case "Potion (Green)":
		{
			refill_shops |= 0010b;
			fill_bottle(2);
			holdup_id = 150;
			break;
		}
		case "Potion (Blue)":
		{
			refill_shops |= 0100b;
			fill_bottle(3);
			holdup_id = 151;
			break;
		}
		case "Bomb Ammo x4":
		{
			pickup_id = 78;
			break;
		}
		case "Bomb Ammo x30":
		{
			pickup_id = 80;
			break;
		}
		case "Super Bomb Ammo x1":
		{
			refill_shops |= 1000b;
			pickup_id = 48;
			break;
		}
		case "Rupees x50":
		{
			pickup_id = 39;
			break;
		}
		case "Rupees x100":
		{
			pickup_id = 87;
			break;
		}
		case "Rupees x500":
		{
			pickup_id = 171;
			break;
		}
		case "Compass 1":
		case "Compass 2":
		case "Compass 3":
		case "Compass 4":
		case "Compass 5":
		case "Compass 6":
		case "Compass 7":
		case "Compass 8":
		{
			sprintf(ptr, "%s", itm->item_name);
			Game->LItems[itm->item_name[-2]-'0'] |= LI_COMPASS;
			holdup_id = 22;
			break;
		}
		case "Map 1":
		case "Map 2":
		case "Map 3":
		case "Map 4":
		case "Map 5":
		case "Map 6":
		case "Map 7":
		case "Map 8":
		{
			sprintf(ptr, "%s", itm->item_name);
			Game->LItems[itm->item_name[-2]-'0'] |= LI_MAP;
			holdup_id = 21;
			break;
		}
		case "LKey 1":
		case "LKey 2":
		case "LKey 3":
		case "LKey 5":
		case "LKey 6":
		case "LKey 7":
		case "LKey 8":
		{
			sprintf(ptr, "%s", itm->item_name);
			++Game->LKeys[itm->item_name[-2]-'0'];
			holdup_id = 84;
			break;
		}
		case "Boss Key 1":
		case "Boss Key 2":
		case "Boss Key 3":
		case "Boss Key 5":
		case "Boss Key 6":
		case "Boss Key 7":
		case "Boss Key 8":
		case "Boss Key 9":
		{
			sprintf(ptr, "%s", itm->item_name);
			Game->LItems[itm->item_name[-2]-'0'] |= LI_BOSSKEY;
			holdup_id = 67;
			break;
		}
	}
	if(pickup_id > -1)
	{
		itemdata id = Game->LoadItemData(pickup_id);
		id->MinHearts = 0;
		itemsprite spr = Screen->CreateItem(pickup_id);
		spr->ForceGrab = true;
		spr->PickupString = 0;
		spr->Pickup ~= IP_HOLDUP;
		spr->NoSound = true;
		id->GetDisplayName(ptr);
		char32 buf[1];
		sprintf(buf,"Slot %d", id->Attributes[0]);
		sprintf(ptr,ptr,buf);
		unless(ptr[0])
			id->GetName(ptr);
		return pickup_id;
	}
	unless(ptr[0])
		sprintf(ptr,"%s",itm->item_name);
	return holdup_id;
}
int get_lga3_item(Archipelago::NetworkItem itm, int number)
{
	#option STRING_SWITCH_CASE_INSENSITIVE on
	switch(itm->item_name)
	{
		case "Nothing":
		{
			return -1;
		}
		case "Progressive Sword":
		{
			switch(number)
			{
				case 1:
					return 5;
				case 2:
					return 6;
				case 3:
					return 7;
				case 4:
					return 36;
			}
			break;
		}
		case "Progressive Tunic":
		{
			switch(number)
			{
				case 1:
					return 17;
				case 2:
					return 18;
				case 3:
					return 61;
			}
			break;
		}
		case "Progressive Bottle":
		{
			switch(number)
			{
				case 1:
					return 145;
				case 2:
					return 146;
				case 3:
					return 147;
				case 4:
					return 148;
			}
			break;
		}
		case "Progressive Jump":
		{
			switch(number)
			{
				case 1:
					return 91;
				case 2:
					return 158;
			}
			break;
		}
		case "Progressive Bomb Bag":
		{
			switch(number)
			{
				case 1:
					return 81;
				case 2:
					return 82;
				case 3:
					return 83;
			}
			break;
		}
		case "Progressive Quiver":
		{
			switch(number)
			{
				case 1:
					return 74;
				case 2:
					return 75;
				case 3:
					return 76;
			}
			break;
		}
		case "Progressive Magic Ring":
		{
			switch(number)
			{
				case 1:
					return 115;
				case 2:
					return 116;
				case 3:
					return 117;
				case 4:
					return 118;
			}
			break;
		}
		case "Progressive Life Ring":
		{
			switch(number)
			{
				case 1:
					return 112;
				case 2:
					return 113;
				case 3:
					return 114;
			}
			break;
		}
		case "Progressive Charge Ring":
		{
			switch(number)
			{
				case 1:
					return 101;
				case 2:
					return 102;
			}
			break;
		}
		case "Progressive Shield":
		{
			switch(number)
			{
				case 1:
					return 93;
				case 2:
					return 8;
				case 3:
					return 37;
			}
			break;
		}
		case "Progressive Boomerang":
		{
			switch(number)
			{
				case 1:
					return 23;
				case 2:
					return 24;
				case 3:
					return 35;
			}
			break;
		}
		case "Progressive Lantern":
		{
			switch(number)
			{
				case 1:
					return 10;
				case 2:
					return 11;
			}
			break;
		}
		case "Progressive Wallet":
		{
			switch(number)
			{
				case 1:
					return 41;
				case 2:
					return 42;
			}
			break;
		}
		case "Progressive Coupon":
		{
			switch(number)
			{
				case 1:
					return 109;
				case 2:
					return 110;
				case 3:
					return 111;
			}
			break;
		}
		case "Progressive Bracelet":
		{
			switch(number)
			{
				case 1:
					return 19;
				case 2:
					return 56;
			}
			break;
		}
		case "Progressive Hookshot":
		{
			switch(number)
			{
				case 1:
					return 52;
				case 2:
					return 89;
			}
			break;
		}
		case "Progressive Traction":
		{
			switch(number)
			{
				case 1:
					return 154;
				case 2:
					return 155;
			}
			break;
		}
		case "Progressive Arrows":
		{
			switch(number)
			{
				case 1:
					return 13;
				case 2:
					return 14;
				case 3:
					return 57;
			}
			break;
		}
		case "Bow":
		{
			return 15;
		}
		case "Wand":
		{
			return 25;
		}
		case "Magic Book":
		{
			return 32;
		}
		case "Hammer":
		{
			return 54;
		}
		case "Magic Rock":
		{
			return 169;
		}
		case "Divine Fire":
		{
			return 64;
		}
		case "Divine Protection":
		{
			return 66;
		}
		case "Divine Escape":
		{
			return 65;
		}
		case "Flippers":
		{
			return 51;
		}
		case "Ocarina":
		{
			return 31;
		}
		case "Lens of Truth":
		{
			return 53;
		}
		case "Cheese":
		{
			return 16;
		}
		case "Scroll: Cross Beams":
		{
			return 95;
		}
		case "Scroll: Peril Beam":
		{
			return 103;
		}
		case "Scroll: Hurricane Spin":
		{
			return 98;
		}
		case "Heart Container":
		{
			return 28;
		}
		case "Magic Container":
		{
			return 58;
		}
		case "Half Magic":
		{
			return 172;
		}
		case "Triforce Fragment":
		{
			return 20;
		}
		case "Potion (Red)":
		{
			return 149;
		}
		case "Potion (Blue)":
		{
			return 151;
		}
		case "Potion (Green)":
		{
			return 150;
		}
		case "Bomb Ammo x4":
		{
			return 78;
		}
		case "Bomb Ammo x30":
		{
			return 80;
		}
		case "Super Bomb Ammo x1":
		{
			return 48;
		}
		case "Rupees x50":
		{
			return 39;
		}
		case "Rupees x100":
		{
			return 87;
		}
		case "Rupees x500":
		{
			return 171;
		}
		case "Compass 1":
		case "Compass 2":
		case "Compass 3":
		case "Compass 4":
		case "Compass 5":
		case "Compass 6":
		case "Compass 7":
		case "Compass 8":
		{
			return 22;
		}
		case "Map 1":
		case "Map 2":
		case "Map 3":
		case "Map 4":
		case "Map 5":
		case "Map 6":
		case "Map 7":
		case "Map 8":
		{
			return 21;
		}
		case "LKey 1":
		case "LKey 2":
		case "LKey 3":
		case "LKey 5":
		case "LKey 6":
		case "LKey 7":
		case "LKey 8":
		{
			return 84;
		}
		case "Boss Key 1":
		case "Boss Key 2":
		case "Boss Key 3":
		case "Boss Key 5":
		case "Boss Key 6":
		case "Boss Key 7":
		case "Boss Key 8":
		case "Boss Key 9":
		{
			return 67;
		}
	}
	return -1;
}

void get_item(Archipelago::NetworkItem itm, int number)
{
	using namespace Archipelago;
	char32 buf[1];
	int id = silent_get_item(itm,number,buf);
	if(id < 0)
		id = AP_HOLDUP_ITEM;
	HoldUpItem(id, 0);
	Audio->PlaySound(SFX_JINGLE);
	NetworkPlayer plr = players[itm->player_id-1];
	NetworkSlot slot = slots[plr->slot_id-1];
	sprintf(buf, "%s sent you your '%s', from their %s!", slot->name, buf, itm->location_name);
	popup_msg(buf);
}

void self_item(Archipelago::NetworkItem itm, int number)
{
	char32 buf[1];
	int id = silent_get_item(itm,number,buf);
	if(id < 0)
		id = AP_HOLDUP_ITEM;
	HoldUpItem(id, 0);
	Audio->PlaySound(SFX_JINGLE);
	sprintf(buf, "You found your own '%s' at %s!", buf, itm->location_name);
	popup_msg(buf);
}

void remote_item(Archipelago::NetworkItem itm)
{
	using namespace Archipelago;
	char32 buf[1];
	NetworkPlayer plr = players[itm->player_id-1];
	NetworkSlot slot = slots[plr->slot_id-1];
	int id = AP_HOLDUP_ITEM;
	unless(strcmp(slot->game,slots[players[ap_player_id-1]->slot_id-1]->game))
	{
		int id2 = get_lga3_item(itm, 1);
		if(id2 > -1)
			id = id2;
	}
	HoldUpItem(id, 0);
	Audio->PlaySound(SFX_JINGLE);

	sprintf(buf, "You found %s's '%s' at %s!", slot->name, itm->item_name, itm->location_name);
	popup_msg(buf);
}

void popup_msg(char32 buf)
{
	messagedata md = Game->LoadMessageData(61);
	md->Set(buf);
	Screen->Message(61);
}

generic script AP_Pickup_Runner
{
	int got_ganon_msg = 0;
	void run()
	{
		int delay = 30;
		while(true)
		{
			Waitframe();
			if(delay)
			{
				--delay;
				continue;
			}
			switch((Game->CurMap << 8) + Game->CurScreen)
			{
				case 0x30C:
				case 0x31C:
					continue;
			}
			switch(Hero->Action)
			{
				case LA_NONE:
				case LA_WALKING:
				case LA_SWIMMING:
					break;
				default:
					continue;
			}
			if(Screen->ShowingMessage)
				continue;
				
			delay = 5;
			if(Archipelago::NetworkItem locinfo = poll_collect())
			{
				if(locinfo->player_id == Archipelago::ap_player_id)
				{
					int indx = locinfo->localize_item_id();
					Archipelago::mark_item_collected(indx);
					self_item(locinfo, Archipelago::collected_item(indx));
				}
				else remote_item(locinfo);
			}
			else if(Archipelago::NetworkItem recvinfo = poll_receive())
			{
				if(recvinfo->player_id == Archipelago::ap_player_id)
					self_item(recvinfo, recvd_count);
				else get_item(recvinfo, recvd_count);
				delete recvinfo;
			}
			else delay = 0;
			if((Game->LItems[8] & LI_TRIFORCE) && got_ganon_msg < 2)
			{
				if(got_ganon_msg < 1)
				{
					Screen->Message(36);
					got_ganon_msg = 1;
				}
				if(Hero->Item[6] || Hero->Item[7] || Hero->Item[36]) //L2+ Sword
				{
					if(Hero->Item[15] && Game->MCounter[CR_ARROWS] && (Hero->Item[14] || Hero->Item[57])) //Bow + Quiver + Silver Arrows
					{
						if(Game->LItems[9] & LI_BOSSKEY) //L9 bosskey
						{
							//(L2 Sword + Bow + Quiver + L2 Arrows + 8 Triforce Fragments)
							popup_msg("You now have access to the final boss, in the east of the desert.");
							got_ganon_msg = 2;
						}
					}
				}
			}
		}
	}
}

generic script AP_ScreenChange_Runner
{
	using namespace Archipelago;
	NetworkItem locs[AP_DUMMY_COUNT];
	void run()
	{
		this->ReloadState[GENSCR_ST_CHANGE_SCREEN] = true;
		Screen->ItemSFX = 0;
		do Waitframe(); while(Game->CurScreen >= 0x80);
		if(Game->CurMap == 3 && Game->CurScreen == 0x0C)
			Archipelago::send_status_update(Archipelago::CLIENT_GOAL);
		get_ap_locs(locs);
		for(int q = 0; q < AP_DUMMY_COUNT; ++q)
		{
			itemdata idata;
			if(locs[q])
			{
				NetworkPlayer plyr = players[locs[q]->player_id-1];
				NetworkSlot slot = slots[plyr->slot_id-1];
				int visual_id = AP_HOLDUP_ITEM;
				auto cur_plyr = players[ap_player_id-1];
				auto cur_slot = slots[cur_plyr->slot_id-1];
				unless(strcmp(slot->game,cur_slot->game))
				{
					int collected = 1;
					if(locs[q]->player_id == ap_player_id)
						collected += collected_item(locs[q]->localize_item_id());
					int id = get_lga3_item(locs[q], collected);
					if(id > -1)
						visual_id = id;
				}
				idata = Game->LoadItemData(visual_id);
			}
			else idata = Game->LoadItemData(AP_HOLDUP_ITEM);
			itemdata dummy = Game->LoadItemData(AP_DUMMY_START+q);
			dummy->Tile = idata->Tile;
			dummy->CSet = idata->CSet;
			dummy->AFrames = idata->AFrames;
			dummy->ASpeed = idata->ASpeed;
			dummy->Delay = idata->Delay;
			dummy->Flash = idata->Flash;
			combodata dummycd = Game->LoadComboData(AP_DUMMY_COMBO_START+q);
			dummycd->OriginalTile = dummycd->Tile = idata->Tile;
			dummycd->Frames = idata->AFrames;
			dummycd->ASpeed = idata->ASpeed;
			dummycd->AClk = 0;
		}
		while(true)
			Waitframe();
	}
}
generic script AP_ItemCollect_Handler
{
	void run()
	{
		using namespace Archipelago;
		this->EventListen[GENSCR_EVENT_COLLECT_ITEM] = true;
		while(true)
		{
			if(WaitEvent() == GENSCR_EVENT_COLLECT_ITEM)
			{
				int id = Game->EventData[GENEV_ITEMCOL_ID];
				Game->EventData[GENEV_ITEMCOL_PICKUP] ~= IP_HOLDUP;
				int dummy_id = id - AP_DUMMY_START;
				if(dummy_id < 0 || dummy_id >= AP_DUMMY_COUNT)
					continue;
				NetworkItem itm = AP_ScreenChange_Runner.locs[dummy_id];
				unless(itm)
				{
					if(Archipelago::AP_LOG)
						printf("[ERR] Invalid pickup location '%dx%02X'[%d]\n", Game->CurMap, Game->CurScreen, dummy_id);
					continue;
				}
				auto loc_id = itm->localize_location_id();
				if(Archipelago::AP_DEV_LOG)
				{
					printf("[DEV] Collecting item '%s' for %d from location '%s'\n", itm->item_name, itm->player_id, itm->location_name);
					printf("[DEV] Item was already collected? %s\n", checked_location(loc_id) ? "true" : "false");
				}
				collect_location(loc_id);
			}
		}
	}
}

void get_ap_locs(Archipelago::NetworkItem locs)
{
	int key = (Game->CurMap << 8) + Game->CurScreen;
	for(int q = 0; q < SizeOfArray(locs); ++q)
		if(locs[q])
			locs[q] = NULL; //don't 'delete', as 'find_loc' returns globally-owned objects
	switch(key)
	{
		case 0x153:
			locs[0] = find_loc("Sword Under Block");
			break;
		case 0x137:
			locs[0] = find_loc("Sword Under Tree");
			break;
		case 0x135:
			locs[0] = find_loc("Boomerang Under Rock");
			break;
		case 0x11B:
			locs[0] = find_loc("KillAll: HeartC 1");
			break;
		case 0x10C:
			locs[0] = find_loc("KillAll: MagicC 1");
			break;
		case 0x300:
			locs[0] = find_loc("Kak Red Shop 1");
			locs[1] = find_loc("Kak Red Shop 2");
			locs[2] = find_loc("Kak Red Shop 3");
			locs[3] = find_loc("Kak Red Shop 4");
			break;
		case 0x301:
			locs[0] = find_loc("Kak Potion Shop 1");
			locs[1] = find_loc("Kak Potion Shop 2");
			locs[2] = find_loc("Kak Potion Shop 3");
			break;
		case 0x302:
			locs[0] = find_loc("Kak Purple Shop 1");
			locs[1] = find_loc("Kak Purple Shop 2");
			locs[2] = find_loc("Kak Purple Shop 3");
			break;
		case 0x347:
			locs[0] = find_loc("Kak Bombable Cave");
			break;
		case 0x370:
			locs[0] = find_loc("Kak Magic Rock Cave");
			break;
		case 0x102:
			locs[0] = find_loc("Hidden HeartC 1");
			break;
		case 0x111:
			locs[0] = find_loc("Hidden MagicC 1");
			break;
		case 0x121:
			locs[0] = find_loc("KillAll: MagicC 2");
			break;
		case 0x140:
			locs[0] = find_loc("KillAll: HeartC 2");
			break;
		case 0x142:
			locs[0] = find_loc("KillAll: MagicC 3");
			break;
		case 0x104:
			locs[0] = find_loc("24-Headed Dragon");
			break;
		case 0x250:
			locs[0] = find_loc("Cave Shop 1");
			locs[1] = find_loc("Cave Shop 2");
			locs[2] = find_loc("Cave Shop 3");
			break;
		case 0x270:
			locs[0] = find_loc("Super Bomb Shop");
			break;
		case 0x107:
			locs[0] = find_loc("KillAll: Cross Beams");
			break;
		case 0x106:
			locs[0] = find_loc("KillAll: MagicC 4");
			break;
		case 0x105:
			locs[0] = find_loc("Hidden MagicC 2");
			break;
		case 0x12E:
			locs[0] = find_loc("Hidden Half Magic");
			break;
		case 0x14D:
			locs[0] = find_loc("Traction Boots");
			break;
		case 0x14F:
			locs[0] = find_loc("Hidden HeartC 2");
			break;
		case 0x15B:
			locs[0] = find_loc("KillAll: MagicC 5");
			break;
		case 0x15D:
			locs[0] = find_loc("Divine Protection");
			break;
		case 0x16B:
			locs[0] = find_loc("Hidden HeartC 3");
			break;
		case 0x15F:
			locs[0] = find_loc("KillAll: Peril Beam");
			break;
		case 0x473:
			locs[0] = find_loc("L1: Compass");
			break;
		case 0x462:
			locs[0] = find_loc("L1 KillAll: Map");
			break;
		case 0x463:
			locs[0] = find_loc("L1 KillAll: LKey");
			break;
		case 0x475:
			locs[0] = find_loc("L1 KillAll: Wallet");
			break;
		case 0x466:
			locs[0] = find_loc("L1 KillAll: Life Ring");
			break;
		case 0x477:
			locs[0] = find_loc("L1 KillAll: Bomb Ammo");
			break;
		case 0x467:
			locs[0] = find_loc("L1: Bottle");
			break;
		case 0x478:
			locs[0] = find_loc("L1 KillAll: Quiver");
			break;
		case 0x468:
			locs[0] = find_loc("L1 KillAll: Boss Key");
			break;
		case 0x464:
			locs[0] = find_loc("L1 Boss Reward");
			break;
		case 0x465:
			locs[0] = find_loc("L1 Dungeon Reward");
			break;
		case 0x47C:
			locs[0] = find_loc("L2 KillAll: Map");
			break;
		case 0x47E:
			locs[0] = find_loc("L2 KillAll: Compass");
			break;
		case 0x46F:
			locs[0] = find_loc("L2 KillAll: Sword");
			break;
		case 0x47F:
			locs[0] = find_loc("L2 KillAll: LKey");
			break;
		case 0x44F:
			locs[0] = find_loc("L2: Bottle");
			break;
		case 0x46B:
			locs[0] = find_loc("L2 KillAll: Heart Ring");
			break;
		case 0x47B:
			locs[0] = find_loc("L2 KillAll: Boss Key");
			break;
		case 0x44B:
			locs[0] = find_loc("L2: Coupon");
			break;
		case 0x44D:
			locs[0] = find_loc("L2 KillAll: Bomb Ammo");
			break;
		case 0x45D:
			locs[0] = find_loc("L2 Boss Reward");
			break;
		case 0x46D:
			locs[0] = find_loc("L2 Dungeon Reward");
			break;
		case 0x400:
			locs[0] = find_loc("L3: Roc's Feather");
			break;
		case 0x401:
			locs[0] = find_loc("L3 KillAll: Map");
			break;
		case 0x402:
			locs[0] = find_loc("L3: LKey");
			break;
		case 0x403:
			locs[0] = find_loc("L3 KillAll: Compass");
			break;
		case 0x412:
			locs[0] = find_loc("L3 KillAll: Bracelet");
			break;
		case 0x414:
			locs[0] = find_loc("L3 KillAll: Hookshot");
			break;
		case 0x413:
			locs[0] = find_loc("L3: Boss Key");
			break;
		case 0x405:
			locs[0] = find_loc("L3 KillAll: Charge Ring");
			break;
		case 0x406:
			locs[0] = find_loc("L3 Boss Reward");
			break;
		case 0x407:
			locs[0] = find_loc("L3 Dungeon Reward");
			break;
		case 0x420:
			locs[0] = find_loc("L4: Map");
			break;
		case 0x430:
			locs[0] = find_loc("L4: Roc's Cape");
			break;
		case 0x421:
			locs[0] = find_loc("L4: Bomb Bag");
			break;
		case 0x433:
			locs[0] = find_loc("L4: Boomerang");
			break;
		case 0x443:
			locs[0] = find_loc("L4 KillAll: Compass");
			break;
		case 0x424:
			locs[0] = find_loc("L4 KillAll: Longshot");
			break;
		case 0x425:
			locs[0] = find_loc("L4 Boss Reward");
			break;
		case 0x426:
			locs[0] = find_loc("L4 Dungeon Reward");
			break;
		case 0x56D:
			locs[0] = find_loc("L5 KillAll: Compass");
			break;
		case 0x57A:
			locs[0] = find_loc("L5 KillAll: Bomb Ammo");
			break;
		case 0x56A:
			locs[0] = find_loc("L5 KillAll: Hidden LKey");
			break;
		case 0x56B:
			locs[0] = find_loc("L5 KillAll: Map");
			break;
		case 0x56C:
			locs[0] = find_loc("L5 KillAll: Escape Spell");
			break;
		case 0x57B:
			locs[0] = find_loc("L5 KillAll: Bottle");
			break;
		case 0x57D:
			locs[0] = find_loc("L5: Bracelet 2");
			break;
		case 0x55D:
			locs[0] = find_loc("L5 KillAll: Magic Ring");
			break;
		case 0x54C:
			locs[0] = find_loc("L5 KillAll: Boss Key");
			break;
		case 0x55B:
			locs[0] = find_loc("L5 Boss Reward");
			break;
		case 0x55A:
			locs[0] = find_loc("L5 Dungeon Reward");
			break;
		case 0x656:
			locs[0] = find_loc("L6: Compass");
			break;
		case 0x646:
			locs[0] = find_loc("L6 KillAll: Map");
			break;
		case 0x655:
			locs[0] = find_loc("L6: Hidden Money");
			break;
		case 0x647:
			locs[0] = find_loc("L6 KillAll: Bottle");
			break;
		case 0x657:
			locs[0] = find_loc("L6 KillAll: Money 1");
			break;
		case 0x658:
			locs[0] = find_loc("L6: Dragon Miniboss");
			break;
		case 0x648:
			locs[0] = find_loc("L6 KillAll: Wand");
			break;
		case 0x618:
			locs[0] = find_loc("L6 KillAll: Charge Ring");
			break;
		case 0x616:
			locs[0] = find_loc("L6 KillAll: Money 2");
			break;
		case 0x654:
			locs[0] = find_loc("L6: LKey 1");
			break;
		case 0x642:
			locs[0] = find_loc("L6 KillAll: LKey 2");
			break;
		case 0x622:
			locs[0] = find_loc("L6 KillAll: Boss Key");
			break;
		case 0x623:
			locs[0] = find_loc("L6 KillAll: Quiver");
			break;
		case 0x632:
			locs[0] = find_loc("L6 Boss Reward");
			break;
		case 0x630:
			locs[0] = find_loc("L6 Dungeon Reward");
			break;
		case 0x572:
			locs[0] = find_loc("Well: Bomb Bag");
			break;
		case 0x574:
			locs[0] = find_loc("Well: Lens");
			break;
		case 0x562:
			locs[0] = find_loc("Well: Green Potion");
			break;
		case 0x552:
			locs[0] = find_loc("Well: Cheese");
			break;
		case 0x556:
			locs[0] = find_loc("L7 KillAll: Compass");
			break;
		case 0x558:
			locs[0] = find_loc("L7 KillAll: Map");
			break;
		case 0x536:
			locs[0] = find_loc("L7 KillAll: Wallet");
			break;
		case 0x538:
			locs[0] = find_loc("L7 KillAll: Coupon");
			break;
		case 0x515:
			locs[0] = find_loc("L7 KillAll: Shield");
			break;
		case 0x519:
			locs[0] = find_loc("L7 KillAll: LKey 1");
			break;
		case 0x516:
			locs[0] = find_loc("L7 KillAll: LKey 2");
			break;
		case 0x518:
			locs[0] = find_loc("L7 KillAll: Boss Key");
			break;
		case 0x508:
			locs[0] = find_loc("L7 KillAll: Money");
			break;
		case 0x507:
			locs[0] = find_loc("L7 Boss Reward");
			break;
		case 0x506:
			locs[0] = find_loc("L7 Dungeon Reward");
			break;
		case 0x66A:
			locs[0] = find_loc("L8 KillAll: Map");
			break;
		case 0x66E:
			locs[0] = find_loc("L8 KillAll: Compass");
			break;
		case 0x67B:
			locs[0] = find_loc("L8 KillAll: LKey 1");
			break;
		case 0x67D:
			locs[0] = find_loc("L8 KillAll: LKey 2");
			break;
		case 0x64B:
			locs[0] = find_loc("L8 KillAll: LKey 3");
			break;
		case 0x64D:
			locs[0] = find_loc("L8 KillAll: LKey 4");
			break;
		case 0x63B:
			locs[0] = find_loc("L8 KillAll: LKey 5");
			break;
		case 0x63D:
			locs[0] = find_loc("L8 KillAll: LKey 6");
			break;
		case 0x61A:
			locs[0] = find_loc("L8 KillAll: LKey 7");
			break;
		case 0x61E:
			locs[0] = find_loc("L8 KillAll: LKey 8");
			break;
		case 0x63C:
			locs[0] = find_loc("L8: 12-Headed Dragon");
			break;
		case 0x62C:
			locs[0] = find_loc("L8: Plant Bosses");
			break;
		case 0x61C:
			locs[0] = find_loc("L8: Spider Bosses");
			break;
		case 0x61B:
			locs[0] = find_loc("L8: Boss Key");
			break;
		case 0x61D:
			locs[0] = find_loc("L8: Hurricane Spin");
			break;
		case 0x60D:
			locs[0] = find_loc("L8: Silver Arrows");
			break;
		case 0x60C:
			locs[0] = find_loc("L8 Boss Reward");
			break;
		case 0x60B:
			locs[0] = find_loc("L8 Dungeon Reward");
			break;
		case 0x34A:
			locs[0] = find_loc("L9: Tunic Path");
			break;
		case 0x36C:
			locs[0] = find_loc("L9: Magic Path");
			break;
		case 0x34E:
			locs[0] = find_loc("L9: Arrow Path");
			break;
		case 0x33C:
			locs[0] = find_loc("L9: Boss Key");
			break;
	}
}
Archipelago::NetworkItem find_loc(char32 loc_name)
{
	for(int q = 0; q < Archipelago::num_locs; ++q)
	{
		auto loc = Archipelago::location_infos[q];
		unless(strcmp(loc->location_name,loc_name))
		{
			return loc;
		}
	}
	return NULL;
}

enum LocationType
{
	LOCTY_CUSTOM,
	LOCTY_SPECIALITEM,
	LOCTY_ITEM,
	NUM_LOCTY
};
enum LocationAction
{
	LOCAC_PLACEMENT,
	LOCAC_REMOVE,
	LOCAC_UNREMOVE,
	NUM_LOCAC
};
void get_location_data(char32 name, LocationAction action)
{
	mapdata md;
	LocationType ty[AP_DUMMY_COUNT];
	switch(name)
	{
		case "Starting Sword":
		case "Starting Bomb Bag":
		case "Starting Magic Ring":
		case "Starting Shield":
		case "Starting Arrows":
		{
			break;
		}
		case "Sword Under Block":
		{
			md = Game->LoadMapData(1, 0x53);
			ty[0] = LOCTY_SPECIALITEM;
			break;
		}
		case "Sword Under Tree":
		{
			md = Game->LoadMapData(1, 0x37);
			ty[0] = LOCTY_SPECIALITEM;
			break;
		}
		case "Boomerang Under Rock":
		{
			md = Game->LoadMapData(1, 0x35);
			ty[0] = LOCTY_SPECIALITEM;
			break;
		}
		case "KillAll: HeartC 1":
		{
			md = Game->LoadMapData(1, 0x1B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "KillAll: MagicC 1":
		{
			md = Game->LoadMapData(1, 0x0C);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "Kak Red Shop 1":
		{
			md = Game->LoadMapData(3, 0x00);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->SetFFCInitD(1, 0, AP_DUMMY_START+0);
					md->SetFFCInitD(1, 1, 1);
					md->SetFFCInitD(1, 3, 0);
					md->SetFFCInitD(1, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Kak Red Shop 2":
		{
			md = Game->LoadMapData(3, 0x00);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->SetFFCInitD(2, 0, AP_DUMMY_START+1);
					md->SetFFCInitD(2, 1, 1);
					md->SetFFCInitD(2, 3, 0);
					md->SetFFCInitD(2, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Kak Red Shop 3":
		{
			md = Game->LoadMapData(3, 0x00);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->SetFFCInitD(3, 0, AP_DUMMY_START+2);
					md->SetFFCInitD(3, 1, 1);
					md->SetFFCInitD(3, 3, 0);
					md->SetFFCInitD(3, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Kak Red Shop 4":
		{
			md = Game->LoadMapData(3, 0x00);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->SetFFCInitD(4, 0, AP_DUMMY_START+3);
					md->SetFFCInitD(4, 1, 1);
					md->SetFFCInitD(4, 3, 0);
					md->SetFFCInitD(4, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Kak Potion Shop 1":
		{
			md = Game->LoadMapData(3, 0x01);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					for(int q = 2; q < 5; ++q)
					{
						md->FFCData[q+3] = md->FFCData[q];
						md->FFCCSet[q+3] = md->FFCCSet[q];
						md->FFCDelay[q+3] = md->FFCDelay[q];
						md->FFCX[q+3] = md->FFCX[q];
						md->FFCY[q+3] = md->FFCY[q] - 64;
						md->FFCScript[q+3] = md->FFCScript[q];
						for(int ind = 0; ind < 8; ++ind)
							md->SetFFCInitD(q+3, ind, md->GetFFCInitD(q, ind));
					}
					md->SetFFCInitD(5, 5, 1);
					md->SetFFCInitD(6, 5, 2);
					md->SetFFCInitD(7, 5, 3);
					md->SetFFCInitD(2, 0, AP_DUMMY_START+0);
					md->SetFFCInitD(2, 1, 1);
					md->SetFFCInitD(2, 3, 0);
					md->SetFFCInitD(2, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Kak Potion Shop 2":
		{
			md = Game->LoadMapData(3, 0x01);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->SetFFCInitD(3, 0, AP_DUMMY_START+1);
					md->SetFFCInitD(3, 1, 1);
					md->SetFFCInitD(3, 3, 0);
					md->SetFFCInitD(3, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Kak Potion Shop 3":
		{
			md = Game->LoadMapData(3, 0x01);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->SetFFCInitD(4, 0, AP_DUMMY_START+2);
					md->SetFFCInitD(4, 1, 1);
					md->SetFFCInitD(4, 3, 0);
					md->SetFFCInitD(4, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Kak Purple Shop 1":
		{
			md = Game->LoadMapData(3, 0x02);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->SetFFCInitD(2, 0, AP_DUMMY_START+0);
					md->SetFFCInitD(2, 1, 1);
					md->SetFFCInitD(2, 3, 0);
					md->SetFFCInitD(2, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Kak Purple Shop 2":
		{
			md = Game->LoadMapData(3, 0x02);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->SetFFCInitD(3, 0, AP_DUMMY_START+1);
					md->SetFFCInitD(3, 1, 1);
					md->SetFFCInitD(3, 3, 0);
					md->SetFFCInitD(3, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Kak Purple Shop 3":
		{
			md = Game->LoadMapData(3, 0x02);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->SetFFCInitD(4, 0, AP_DUMMY_START+2);
					md->SetFFCInitD(4, 1, 1);
					md->SetFFCInitD(4, 3, 0);
					md->SetFFCInitD(4, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Kak Bombable Cave":
		{
			md = Game->LoadMapData(3, 0x47);
			ty[0] = LOCTY_SPECIALITEM;
			break;
		}
		case "Kak Magic Rock Cave":
		{
			md = Game->LoadMapData(3, 0x70);
			ty[0] = LOCTY_SPECIALITEM;
			break;
		}
		case "Hidden HeartC 1":
		{
			md = Game->LoadMapData(1, 0x02);
			ty[0] = LOCTY_SPECIALITEM;
			break;
		}
		case "Hidden MagicC 1":
		{
			md = Game->LoadMapData(1, 0x11);
			ty[0] = LOCTY_SPECIALITEM;
			break;
		}
		case "KillAll: MagicC 2":
		{
			md = Game->LoadMapData(1, 0x21);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "KillAll: HeartC 2":
		{
			md = Game->LoadMapData(1, 0x40);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "KillAll: MagicC 3":
		{
			md = Game->LoadMapData(1, 0x42);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "24-Headed Dragon":
		{
			md = Game->LoadMapData(1, 0x04);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "Cave Shop 1":
		{
			md = Game->LoadMapData(2, 0x50);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->SetFFCInitD(2, 0, AP_DUMMY_START+0);
					md->SetFFCInitD(2, 1, 1);
					md->SetFFCInitD(2, 3, 0);
					md->SetFFCInitD(2, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Cave Shop 2":
		{
			md = Game->LoadMapData(2, 0x50);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->SetFFCInitD(3, 0, AP_DUMMY_START+1);
					md->SetFFCInitD(3, 1, 1);
					md->SetFFCInitD(3, 3, 0);
					md->SetFFCInitD(3, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Cave Shop 3":
		{
			md = Game->LoadMapData(2, 0x50);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->SetFFCInitD(4, 0, AP_DUMMY_START+2);
					md->SetFFCInitD(4, 1, 1);
					md->SetFFCInitD(4, 3, 0);
					md->SetFFCInitD(4, 4, get_loc_id(name)+1);
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "Super Bomb Shop":
		{
			md = Game->LoadMapData(2, 0x70);
			switch(action)
			{
				case LOCAC_PLACEMENT:
				{
					md->FFCData[5] = md->FFCData[4];
					md->FFCCSet[5] = md->FFCCSet[4];
					md->FFCDelay[5] = md->FFCDelay[4];
					md->FFCX[5] = md->FFCX[4];
					md->FFCY[5] = md->FFCY[4];
					md->FFCFlags[5] = md->FFCFlags[4];
					md->FFCScript[5] = md->FFCScript[4];
					for(int ind = 0; ind < 8; ++ind)
						md->SetFFCInitD(5, ind, md->GetFFCInitD(4, ind));
					md->SetFFCInitD(5, 5, 4);
					md->SetFFCInitD(4, 0, AP_DUMMY_START+0);
					md->SetFFCInitD(4, 1, 1);
					md->SetFFCInitD(4, 3, 0);
					md->SetFFCInitD(4, 4, get_loc_id(name)+1);
					md->FFCX[4] -= 24;
					md->FFCX[5] += 24;
					break;
				}
				case LOCAC_REMOVE:
					break;
			}
			break;
		}
		case "KillAll: Cross Beams":
		{
			md = Game->LoadMapData(1, 0x07);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "KillAll: MagicC 4":
		{
			md = Game->LoadMapData(1, 0x06);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "Hidden MagicC 2":
		{
			md = Game->LoadMapData(1, 0x05);
			ty[0] = LOCTY_SPECIALITEM;
			break;
		}
		case "Hidden Half Magic":
		{
			md = Game->LoadMapData(1, 0x2E);
			ty[0] = LOCTY_SPECIALITEM;
			md->RoomType = RT_SPECIALITEM;
			break;
		}
		case "Traction Boots":
		{
			md = Game->LoadMapData(1, 0x4D);
			ty[0] = LOCTY_SPECIALITEM;
			break;
		}
		case "Hidden HeartC 2":
		{
			md = Game->LoadMapData(1, 0x4F);
			ty[0] = LOCTY_SPECIALITEM;
			break;
		}
		case "KillAll: MagicC 5":
		{
			md = Game->LoadMapData(1, 0x5B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "Divine Protection":
		{
			md = Game->LoadMapData(1, 0x5D);
			ty[0] = LOCTY_SPECIALITEM;
			break;
		}
		case "Hidden HeartC 3":
		{
			md = Game->LoadMapData(1, 0x6B);
			ty[0] = LOCTY_SPECIALITEM;
			break;
		}
		case "KillAll: Peril Beam":
		{
			md = Game->LoadMapData(1, 0x5F);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L1: Compass":
		{
			md = Game->LoadMapData(4, 0x73);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L1 KillAll: Map":
		{
			md = Game->LoadMapData(4, 0x62);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L1 KillAll: LKey":
		{
			md = Game->LoadMapData(4, 0x63);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L1 KillAll: Wallet":
		{
			md = Game->LoadMapData(4, 0x75);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L1 KillAll: Life Ring":
		{
			md = Game->LoadMapData(4, 0x66);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L1 KillAll: Bomb Ammo":
		{
			md = Game->LoadMapData(4, 0x77);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L1: Bottle":
		{
			md = Game->LoadMapData(4, 0x67);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L1 KillAll: Quiver":
		{
			md = Game->LoadMapData(4, 0x78);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L1 KillAll: Boss Key":
		{
			md = Game->LoadMapData(4, 0x68);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L1 Boss Reward":
		{
			md = Game->LoadMapData(4, 0x64);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L1 Dungeon Reward":
		{
			md = Game->LoadMapData(4, 0x65);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L2 KillAll: Map":
		{
			md = Game->LoadMapData(4, 0x7C);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L2 KillAll: Compass":
		{
			md = Game->LoadMapData(4, 0x7E);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L2 KillAll: Sword":
		{
			md = Game->LoadMapData(4, 0x6F);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L2 KillAll: LKey":
		{
			md = Game->LoadMapData(4, 0x7F);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L2: Bottle":
		{
			md = Game->LoadMapData(4, 0x4F);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L2 KillAll: Heart Ring":
		{
			md = Game->LoadMapData(4, 0x6B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L2 KillAll: Boss Key":
		{
			md = Game->LoadMapData(4, 0x7B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L2: Coupon":
		{
			md = Game->LoadMapData(4, 0x4B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L2 KillAll: Bomb Ammo":
		{
			md = Game->LoadMapData(4, 0x4D);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L2 Boss Reward":
		{
			md = Game->LoadMapData(4, 0x5D);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L2 Dungeon Reward":
		{
			md = Game->LoadMapData(4, 0x6D);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L3: Roc's Feather":
		{
			md = Game->LoadMapData(4, 0x00);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L3 KillAll: Map":
		{
			md = Game->LoadMapData(4, 0x01);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L3: LKey":
		{
			md = Game->LoadMapData(4, 0x02);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L3 KillAll: Compass":
		{
			md = Game->LoadMapData(4, 0x03);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L3 KillAll: Bracelet":
		{
			md = Game->LoadMapData(4, 0x12);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L3 KillAll: Hookshot":
		{
			md = Game->LoadMapData(4, 0x14);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L3: Boss Key":
		{
			md = Game->LoadMapData(4, 0x13);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L3 KillAll: Charge Ring":
		{
			md = Game->LoadMapData(4, 0x05);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L3 Boss Reward":
		{
			md = Game->LoadMapData(4, 0x06);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L3 Dungeon Reward":
		{
			md = Game->LoadMapData(4, 0x07);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L4: Map":
		{
			md = Game->LoadMapData(4, 0x20);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L4: Roc's Cape":
		{
			md = Game->LoadMapData(4, 0x30);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L4: Bomb Bag":
		{
			md = Game->LoadMapData(4, 0x21);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L4: Boomerang":
		{
			md = Game->LoadMapData(4, 0x33);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L4 KillAll: Compass":
		{
			md = Game->LoadMapData(4, 0x43);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L4 KillAll: Longshot":
		{
			md = Game->LoadMapData(4, 0x24);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L4 Boss Reward":
		{
			md = Game->LoadMapData(4, 0x25);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L4 Dungeon Reward":
		{
			md = Game->LoadMapData(4, 0x26);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L5 KillAll: Compass":
		{
			md = Game->LoadMapData(5, 0x6D);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L5 KillAll: Bomb Ammo":
		{
			md = Game->LoadMapData(5, 0x7A);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L5 KillAll: Hidden LKey":
		{
			md = Game->LoadMapData(5, 0x6A);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L5 KillAll: Map":
		{
			md = Game->LoadMapData(5, 0x6B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L5 KillAll: Escape Spell":
		{
			md = Game->LoadMapData(5, 0x6C);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L5 KillAll: Bottle":
		{
			md = Game->LoadMapData(5, 0x7B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L5: Bracelet 2":
		{
			md = Game->LoadMapData(5, 0x7D);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L5 KillAll: Magic Ring":
		{
			md = Game->LoadMapData(5, 0x5D);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L5 KillAll: Boss Key":
		{
			md = Game->LoadMapData(5, 0x4C);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L5 Boss Reward":
		{
			md = Game->LoadMapData(5, 0x5B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L5 Dungeon Reward":
		{
			md = Game->LoadMapData(5, 0x5A);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6: Compass":
		{
			md = Game->LoadMapData(6, 0x56);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6 KillAll: Map":
		{
			md = Game->LoadMapData(6, 0x46);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6: Hidden Money":
		{
			md = Game->LoadMapData(6, 0x55);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6 KillAll: Bottle":
		{
			md = Game->LoadMapData(6, 0x47);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6 KillAll: Money 1":
		{
			md = Game->LoadMapData(6, 0x57);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6: Dragon Miniboss":
		{
			md = Game->LoadMapData(6, 0x58);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6 KillAll: Wand":
		{
			md = Game->LoadMapData(6, 0x48);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6 KillAll: Charge Ring":
		{
			md = Game->LoadMapData(6, 0x18);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6 KillAll: Money 2":
		{
			md = Game->LoadMapData(6, 0x16);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6: LKey 1":
		{
			md = Game->LoadMapData(6, 0x54);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6 KillAll: LKey 2":
		{
			md = Game->LoadMapData(6, 0x42);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6 KillAll: Boss Key":
		{
			md = Game->LoadMapData(6, 0x22);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6 KillAll: Quiver":
		{
			md = Game->LoadMapData(6, 0x23);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6 Boss Reward":
		{
			md = Game->LoadMapData(6, 0x32);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L6 Dungeon Reward":
		{
			md = Game->LoadMapData(6, 0x30);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "Well: Bomb Bag":
		{
			md = Game->LoadMapData(5, 0x72);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "Well: Lens":
		{
			md = Game->LoadMapData(5, 0x74);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "Well: Green Potion":
		{
			md = Game->LoadMapData(5, 0x62);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "Well: Cheese":
		{
			md = Game->LoadMapData(5, 0x52);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L7 KillAll: Compass":
		{
			md = Game->LoadMapData(5, 0x56);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L7 KillAll: Map":
		{
			md = Game->LoadMapData(5, 0x58);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L7 KillAll: Wallet":
		{
			md = Game->LoadMapData(5, 0x36);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L7 KillAll: Coupon":
		{
			md = Game->LoadMapData(5, 0x38);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L7 KillAll: Shield":
		{
			md = Game->LoadMapData(5, 0x15);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L7 KillAll: LKey 1":
		{
			md = Game->LoadMapData(5, 0x19);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L7 KillAll: LKey 2":
		{
			md = Game->LoadMapData(5, 0x16);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L7 KillAll: Boss Key":
		{
			md = Game->LoadMapData(5, 0x18);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L7 KillAll: Money":
		{
			md = Game->LoadMapData(5, 0x08);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L7 Boss Reward":
		{
			md = Game->LoadMapData(5, 0x07);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L7 Dungeon Reward":
		{
			md = Game->LoadMapData(5, 0x06);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8 KillAll: Map":
		{
			md = Game->LoadMapData(6, 0x6A);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8 KillAll: Compass":
		{
			md = Game->LoadMapData(6, 0x6E);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8 KillAll: LKey 1":
		{
			md = Game->LoadMapData(6, 0x7B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8 KillAll: LKey 2":
		{
			md = Game->LoadMapData(6, 0x7D);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8 KillAll: LKey 3":
		{
			md = Game->LoadMapData(6, 0x4B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8 KillAll: LKey 4":
		{
			md = Game->LoadMapData(6, 0x4D);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8 KillAll: LKey 5":
		{
			md = Game->LoadMapData(6, 0x3B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8 KillAll: LKey 6":
		{
			md = Game->LoadMapData(6, 0x3D);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8 KillAll: LKey 7":
		{
			md = Game->LoadMapData(6, 0x1A);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8 KillAll: LKey 8":
		{
			md = Game->LoadMapData(6, 0x1E);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8: 12-Headed Dragon":
		{
			md = Game->LoadMapData(6, 0x3C);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8: Plant Bosses":
		{
			md = Game->LoadMapData(6, 0x2C);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8: Spider Bosses":
		{
			md = Game->LoadMapData(6, 0x1C);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8: Boss Key":
		{
			md = Game->LoadMapData(6, 0x1B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8: Hurricane Spin":
		{
			md = Game->LoadMapData(6, 0x1D);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8: Silver Arrows":
		{
			md = Game->LoadMapData(6, 0x0D);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8 Boss Reward":
		{
			md = Game->LoadMapData(6, 0x0C);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L8 Dungeon Reward":
		{
			md = Game->LoadMapData(6, 0x0B);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L9: Tunic Path":
		{
			md = Game->LoadMapData(3, 0x4A);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L9: Magic Path":
		{
			md = Game->LoadMapData(3, 0x6C);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L9: Arrow Path":
		{
			md = Game->LoadMapData(3, 0x4E);
			ty[0] = LOCTY_ITEM;
			break;
		}
		case "L9: Boss Key":
		{
			md = Game->LoadMapData(3, 0x3C);
			ty[0] = LOCTY_ITEM;
			break;
		}
	}
	switch(action)
	{
		case LOCAC_PLACEMENT:
			for(int q = 0; q < AP_DUMMY_COUNT; ++q)
			{
				switch(ty[q])
				{
					case LOCTY_SPECIALITEM:
						md->Catchall = AP_DUMMY_START+q;
						break;
					case LOCTY_ITEM:
						md->Item = AP_DUMMY_START+q;
						break;
				}
			}
			break;
		case LOCAC_REMOVE:
			for(int q = 0; q < AP_DUMMY_COUNT; ++q)
			{
				switch(ty[q])
				{
					case LOCTY_SPECIALITEM:
						md->State[ST_SPECIALITEM] = true;
						break;
					case LOCTY_ITEM:
						md->State[ST_ITEM] = true;
						break;
				}
			}
			break;
		case LOCAC_UNREMOVE:
			for(int q = 0; q < AP_DUMMY_COUNT; ++q)
			{
				switch(ty[q])
				{
					case LOCTY_SPECIALITEM:
						md->State[ST_SPECIALITEM] = false;
						break;
					case LOCTY_ITEM:
						md->State[ST_ITEM] = false;
						break;
				}
			}
			break;
	}
}
void handle_ap_placements()
{
	#option STRING_SWITCH_CASE_INSENSITIVE on
	unless(archipelago_mode) return;
	if(first_launch)
	{
		Hero->Item[5] = false; //L1 Sword
		Hero->Item[13] = false; //L1 Arrows
		Hero->Item[81] = false; //L1 Bomb Bag
		Hero->Item[115] = false; //L1 Magic Ring
		Hero->Item[93] = false; //L1 Shield
		Hero->Item[143] = false; //'Bomb Bag: Menu' dummy item
		Game->MCounter[CR_BOMBS] = 0;
	}
	int start_locs[0];
	for(int q = 0; q < Archipelago::num_locs; ++q)
	{
		Archipelago::NetworkItem itm = Archipelago::check_location_info(q);
		switch(itm->location_name)
		{
			case "Starting Sword":
			case "Starting Bomb Bag":
			case "Starting Magic Ring":
			case "Starting Shield":
			case "Starting Arrows":
			{
				ArrayPushBack(start_locs, q);
				break;
			}
		}
		get_location_data(itm->location_name, LOCAC_PLACEMENT);
	}
	collect_locations(start_locs);
}
int get_loc_id(char32 name)
{
	for(int q = 0; q < Archipelago::num_locs; ++q)
	{
		auto loc = Archipelago::location_infos[q];
		if(strcmp(loc->location_name,name))
			continue;
		return q;
	}
	return -1;
}

Archipelago::NetworkItem collect_queue[0];
Archipelago::NetworkItem receive_queue[0];
int receive_counts[0];
void _collect_location_int(int indx)
{
	ArrayPushBack(collect_queue, Archipelago::check_location_info(indx));
	Archipelago::mark_location_checked(indx);
}
void collect_locations(int arr)
{
	for(int q = 0; q < SizeOfArray(arr);)
	{
		if(Archipelago::checked_location(arr[q]))
		{
			if(Archipelago::AP_DEV_LOG)
				printf("[DEV] Skipping location %d, already collected\n", q);
			ArrayPopAt(arr,q);
		}
		else
			_collect_location_int(arr[q++]);
	}
	Archipelago::send_location_checks_arr(arr);
}
void collect_location(...int[] arr)
{
	collect_locations(arr);
}

int recvd_count;
Archipelago::NetworkItem poll_receive()
{
	if(SizeOfArray(receive_queue))
	{
		recvd_count = ArrayPopFront(receive_counts);
		return ArrayPopFront(receive_queue);
	}
	return NULL;
}

Archipelago::NetworkItem poll_collect()
{
	if(SizeOfArray(collect_queue))
		return ArrayPopFront(collect_queue);
	return NULL;
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
		sprintf(ip, "localhost");
		sprintf(slot, "Player1");
		if(Archipelago::ip[0])
			sprintf(ip,"%s",Archipelago::ip);
		if(Archipelago::port[0])
			sprintf(port,"%s",Archipelago::port);
		if(Archipelago::slot[0])
			sprintf(slot,"%s",Archipelago::slot);
		

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

		while(Archipelago::sock && Archipelago::status < Archipelago::STATUS_DATA_LOADED)
		{
			ColorScreen(7, 0x0F, true);
			Emily::DrawStrings(7, 128, MID_Y, FONT, 0x01, -1, TF_CENTERED, wait_msg, OP_OPAQUE, 2, 256);
			Archipelago::APHandler.handle_single_msg();
			Waitframe();
		}
	}
}

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
		JSONRef r = new JSONRef(ref);
		if(r->sub_find({NULL,{"slot_data","easier_grinding"}}))
			if(r->get_bool())
				set_easier_grinding();
		delete r;
	}
	void on_item_received(NetworkItem itm, int total_count)
	{
		//itemlist is a SINGLE NetworkItem, which has been sent to the player
		//total_count is how many of this item you now own in total
		//'mark_item_collected()' is already called for you for this item, just before this.
		//'itm->localize_item_id()' gives you the item's id relative to the base id
		//'itm->localize_location_id()' does the same for the location; but this is only valid to do if
		//    'itm->player_id == Archipelago::ap_player_id'
		//'itm->player_id' is the ID of the player who sent the item
		auto cpy = itm->copy();
		GlobalObject(cpy);
		unless(cpy->item_name[0])
			Archipelago::fetch_item_names(cpy, true);
		ArrayPushBack(receive_queue, cpy);
		ArrayPushBack(receive_counts, total_count);
	}
	void on_location_scouts(NetworkItem itm)
	{
		//itm is a NetworkItem, which has been hinted via a LocationScouts packet.
		//'itm->item_id' is the item's string ID
		//'itm->location_id' is the string ID for the location
		//'itm->player_id' is the ID of the player who will receive the item
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
	void do_unremove_location(int id)
	{
		//forcibly mark this location as "not collected"
		Archipelago::NetworkItem itm = Archipelago::check_location_info(id);
		get_location_data(itm->location_name, LOCAC_UNREMOVE);
	}
	void do_remove_location(int id)
	{
		//forcibly mark this location as "already collected"
		Archipelago::NetworkItem itm = Archipelago::check_location_info(id);
		get_location_data(itm->location_name, LOCAC_REMOVE);
	}
}
