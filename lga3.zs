#include "std.zh"
#include "ffcscript.zh"

namespace LGA3
{
CONFIG I_ROCSCAPE = 158;
CONFIG I_MAGICROCK = 169;

CONFIG SFX_HINT = 60;
CONFIG HINTREP = 3;
CONFIG HINTMOD = 3;
DEFINE HINTCLK = HINTREP*HINTMOD;

CONFIG MINUTES_PER_DAY = 4; //Length of a day or night in minutes;
CONFIG I_NIGHT = 40; //An unused item ID, placed into Link's inventory or removed to change day/night
CONFIG PALETTE_DAY = 0x000, PALETTE_NIGHT = 0x00C;

DEFINE BS_EMPTY = 0;
DEFINE BS_POTIONRED = 1;
DEFINE BS_POTIONGREEN = 2;
DEFINE BS_POTIONBLUE = 3;
DEFINE BS_POTIONFAIRY = 4;

bool SelectPressInput(int input){
    if(input == 0) return Hero->PressA;
    else if(input == 1) return Hero->PressB;
    else if(input == 2) return Hero->PressL;
    else if(input == 3) return Hero->PressR;
}
void SetInput(int input, bool state){
    if(input == 0) Hero->InputA = state;
    else if(input == 1) Hero->InputB = state;
    else if(input == 2) Hero->InputL = state;
    else if(input == 3) Hero->InputR = state;
}

CONFIG I_BOTTLE1 = 145;
CONFIG I_BOTTLE2 = 146;
CONFIG I_BOTTLE3 = 147;
CONFIG I_BOTTLE4 = 148;
bool CanFillBottle()
{
	int bottles[4] = {I_BOTTLE1, I_BOTTLE2, I_BOTTLE3, I_BOTTLE4};
	for(int q = 0; q < 4; ++q)
	{
		if(Hero->Item[bottles[q]] && !Game->BottleState[q])
			return true;
	}
	return false;
}
bool ClearBottle(int state)
{
	int bottles[4] = {I_BOTTLE1, I_BOTTLE2, I_BOTTLE3, I_BOTTLE4};
	for(int q = 0; q < 4; ++q)
	{
		if(Hero->Item[bottles[q]] && Game->BottleState[q] == state)
		{
			Game->BottleState[q] = 0;
			return true;
		}
	}
	return false;
}

void ffcvis(ffc f, bool vis)
{
	f->Flags[FFCF_LENSVIS] = f->Flags[FFCF_LENSINVIS] = !vis;
}

CONFIG C_BLACK = 0x0F;
CONFIG C_WHITE = 0x01;
CONFIG STR_NOBOTTLE = 2;
CONFIG STR_CANTAFFORD = 1;
ffc script ItemShop
{
	void run(int id, bool noDupes, int price, bool potion)
	{
		if(Hero->Item[I_WEALTHMEDAL3])
			price*=.25;
		else if(Hero->Item[I_WEALTHMEDAL2])
			price*=.5;
		else if(Hero->Item[I_WEALTHMEDAL])
			price *=.75;
		itemdata ic = Game->LoadItemData(id);
		bool checked = false;
		while(true)
		{
			if(noDupes && Hero->Item[id])
			{
				ffcvis(this, false);
				Quit();
			}
			ffcvis(this, true);
			if(Abs(Hero->X-this->X)<=8 && Abs(Hero->Y-this->Y)<=8)
			{
				unless(checked)
				{
					checked = true;
					if(Game->Counter[CR_RUPEES]+Game->DCounter[CR_RUPEES]>=price)
					{
						if(potion && !CanFillBottle())
						{
							Screen->Message(STR_NOBOTTLE);
							NoAction();
						}
						else
						{
							item itm = CreateItemAt(id, Hero->X, Hero->Y);
							itm->Pickup = IP_HOLDUP;
							Game->DCounter[CR_RUPEES] -= price;
							if(noDupes)
								ffcvis(this, false);
							for(int q = 0; q < 10; ++q)
								WaitNoAction();
						}
					}
					else
					{
						Screen->Message(STR_CANTAFFORD);
					}
				}
			}
			else
			{
				checked = false;
			}
			DrawPrice(this, price);
			Waitframe();
		}
	}
	void DrawPrice(ffc this, int price)
	{
		int xoff = -2;
		if(price>999)
			xoff = -8;
		else if(price>99)
			xoff = -6;
		else if(price>9)
			xoff = -4;
		Screen->DrawInteger(5, this->X+8+xoff+1, this->Y+18+1, FONT_Z3SMALL, C_BLACK, -1, -1, -1, price, 0, 128);
		Screen->DrawInteger(5, this->X+8+xoff, this->Y+18, FONT_Z3SMALL, C_WHITE, -1, -1, -1, price, 0, 128);
	}
}

itemdata script RocsCape
{
	void run(int height, int time, int jumpPower)
	{
		unless(IsSideview())
		{
			if(int sfx = Game->MiscSFX[MISCSFX_ERROR])
				Game->PlaySound(sfx);
			return;
		}
		
		if(Hero->Climbing)
		{
			Game->PlaySound(SFX_JUMP);
			Hero->Climbing = false;
			Hero->Jump = 0;
		}
		else if(IsSideview() ? Hero->Standing : !Hero->Z)
		{
			Hero->Jump = jumpPower;
			Game->PlaySound(SFX_JUMP);
			int targy = Hero->Y-(height*16);
			for(int q = time; q > 0; --q)
			{
				if(Hero->Y == targy || Hero->Jump < 0)
					Hero->Jump = 0;
				Waitframe();
				if(Hero->Standing && Hero->ItemB == this->ID && Hero->PressB)
				{
					Hero->Jump = jumpPower;
					Game->PlaySound(SFX_JUMP);
					targy = Hero->Y-(height*16);
					q = time;
				}
			}
		}
	}
}

CONFIG CR_SECONDS = CR_CUSTOM1;
@InitScript(0)
global script Init
{
	void run()
	{
		Game->MCounter[CR_SECONDS] = MAX_COUNTER;
		Game->Counter[CR_SECONDS] = MINUTES_PER_DAY*60;
	}
}
generic script DayNight
{
	void toggle_night()
	{
		Hero->Item[I_NIGHT] = !Hero->Item[I_NIGHT];
	}
	void update_night()
	{
		dmapdata dm = Game->LoadDMapData(Game->CurDMap);
		unless(dm->Flagset[DMFS_SCRIPT5])
			return;
		bool night = Hero->Item[I_NIGHT];
		if(night && dm->Palette == PALETTE_DAY)
			dm->Palette = PALETTE_NIGHT;
		else if(!night && dm->Palette == PALETTE_NIGHT)
			dm->Palette = PALETTE_DAY;
	}
	genericdata gd;
	void run()
	{
		gd = this;
		this->DataSize = 1;
		this->Data[0] = ((Game->Time%60L)/1L)%60;
		while(true)
		{
			tick();
			Waitframe();
		}
	}
	void tick()
	{
		if(++(gd->Data[0]) >= 60)
		{
			gd->Data[0] -= 60;
			unless(--Game->Counter[CR_SECONDS])
			{
				Game->Counter[CR_SECONDS] = MINUTES_PER_DAY*60;
				toggle_night();
			}
		}
		update_night();
	}
}

void widg_vis(subscreenwidget widg, bool vis)
{
	if(!widg) return;
	widg->VisibleFlags[SUBVISIB_CLOSED] = vis;
	widg->VisibleFlags[SUBVISIB_OPEN] = vis;
	widg->VisibleFlags[SUBVISIB_SCROLLING] = vis;
}

generic script updateSubscr
{
	void run()
	{
		while(true)
		{
			WaitEvent();
			dmapdata dm = Game->LoadDMapData(Game->CurDMap);
			{ //active
				auto pg = Game->LoadASubData(-1)->Pages[0];
				{ //dungeon cover
					auto type = dm->Type&11b;
					bool ow = (type == DMAP_OVERWORLD || type == DMAP_BSOVERWORLD);
					subscreenwidget ws[2];
					ws[0] = pg->GetWidget("dungeoncover");
					ws[1] = pg->GetWidget("dungeoncover2");
					for(w : ws)
						widg_vis(w, ow);
				}
			}
			{ //passive
				auto pg = Game->LoadPSubData(-1)->Pages[0];
				{ //rupee
					int cs = 13;
					if(Hero->Item[I_WALLET999])
						cs = 8;
					else if(Hero->Item[I_WALLET500])
						cs = 7;
					auto widg = pg->GetWidget("rupee");
					if(widg)
						widg->CSet[0] = cs;
				}
				{ //arrow
					int crn = 0;
					if(Hero->Item[I_ARROW3])
						crn = 2;
					else if(Hero->Item[I_ARROW2])
						crn = 1;
					auto widg = pg->GetWidget("arrow");
					if(widg)
						widg->Corner[0] = crn;
				}
				{ //sbombs
					bool vis = Game->MCounter[CR_SBOMBS] > 0;
					subscreenwidget ws[2];
					ws[0] = pg->GetWidget("sbicon");
					ws[1] = pg->GetWidget("sbctr");
					for(w : ws)
						widg_vis(w, vis);
				}
			}
			{ //overlay
				auto pg = Game->LoadOSubData(-1)->Pages[0];
				{ //dungeon prize
					bool has_prize = Game->LItems[Game->CurLevel] & LI_TRIFORCE;
					widg_vis(pg->GetWidget("prize"), has_prize);
					widg_vis(pg->GetWidget("bosskey"), !has_prize);
				}
			}
		}
	}
}

generic script MagicRock
{
	int type = -1;
	void run(int delay_seconds)
	{
		int delay = delay_seconds*60;
		auto pg = Game->LoadOSubData(0)->Pages[0];
		auto enm_itm = pg->GetWidget("enemy_item");
		auto enm_sec = pg->GetWidget("enemy_secret");
		auto sec = pg->GetWidget("secret");
		until(Hero->Item[I_MAGICROCK])
			Waitframe();
		type = -1;
		int hintclk = 0;
		bool reset = false;
		while(true)
		{
			if(reset || type < 0)
			{
				widg_vis(enm_itm, false);
				widg_vis(enm_sec, false);
				widg_vis(sec, false);
				reset = false;
			}
			switch(type)
			{
				case -1:
					type = 0;
					for(int q = 0; q < delay && !type; ++q)
					{
						if(Game->Scrolling[SCROLL_DIR] > -1)
							--q;
						Waitframe();
					}
					if(type) continue;
					
					if(ScreenEFlag(SEF_LIST2,SEFL2_ENEMIES_ITEM) && !Screen->State[ST_ITEM])
						type = 1;
					else if(ScreenEFlag(SEF_LIST2,SEFL2_ENEMEIS_SECRET) && !Screen->SecretsTriggered())
						type = 2;
					else if(ScreenFlag(SF_MISC,SFM_SCRIPT1) && !Screen->SecretsTriggered())
						type = 3;
					else if(!Screen->State[ST_SPECIALITEM])
						switch(Screen->RoomType)
						{
							case RT_MAGICUPGRADE:
							case RT_SPECIALITEM:
								type = 4;
								break;
						}
					widg_vis(enm_itm, type == 1);
					widg_vis(enm_sec, type == 2);
					widg_vis(sec, type >= 3);
					if(type > 0)
						hintclk = HINTCLK;
					break;
				case 1:
					if(Screen->State[ST_ITEM])
					{
						reset = true;
						type = 0;
					}
					break;
				case 2:
				case 3:
					if(Screen->SecretsTriggered())
					{
						reset = true;
						type = 0;
					}
					break;
				case 4:
					if(Screen->State[ST_SPECIALITEM])
					{
						reset = true;
						type = 0;
					}
					break;
			}
			if(hintclk)
			{
				unless(hintclk-- % HINTMOD)
					Audio->PlaySound(SFX_HINT);
			}
			Waitframes(5);
		}
	}
}
generic script MagicRockEvt
{
	void run()
	{
		auto pg = Game->LoadOSubData(0)->Pages[0];
		auto enm_itm = pg->GetWidget("enemy_item");
		auto enm_sec = pg->GetWidget("enemy_secret");
		auto sec = pg->GetWidget("secret");
		until(Hero->Item[I_MAGICROCK])
			Waitframe();
		while(true)
		{
			WaitEvent();
			MagicRock.type = -1;
		}
	}
}

ffc script GoddessSpellCheck
{
	void run(int flagN, int flagD, int flagF, int layer, bool perm)
	{
		bool N, F, D, done;
		while(true)
		{
			if(usedItem(I_NAYRUSLOVE, true))
			{
				unless(N)
					triggerComboLayer(flagN, layer);
				N = true;
			}
			if(usedItem(I_FARORESWIND, true))
			{
				unless(F)
					triggerComboLayer(flagF, layer);
				F = true;
			}
			if(usedItem(I_DINSFIRE, true))
			{
				unless(D)
					triggerComboLayer(flagD, layer);
				D = true;
			}
			if(N && F && D && !done)
			{
				Screen->TriggerSecrets();
				if(perm)
					Screen->State[ST_SECRET]=true;
				Game->PlaySound(SFX_SECRET);
				done = true;
			}
			Waitframe();
		}
	}
	
	void triggerComboLayer(int flag, int layer)
	{
		for(int q = 0; q < 176; ++q)
		{
			if(ComboFI(q,flag))
				SetLayerComboD(layer,q,GetLayerComboD(layer,q)+1);
		}
	}
	
	bool usedItem(int i, bool kill)
	{
		if(GetEquipmentB()==i&&Hero->InputB)
		{
			if(kill)
				Hero->InputB=false;
			return true;
		}
		if(GetEquipmentA()==i&&Hero->InputA)
		{
			if(kill)
				Hero->InputA=false;
			return true;
		}
		return false;
	}
}

subscreendata script DayNightTick
{
	void run()
	{
		while(true)
		{
			DayNight.tick();
			Waitframe();
		}
	}
}

const int CT_ICE = 146;//Combo type used for ice, default 'Script 5'
const int ICE_MAX = 2.5;//Max speed on ice in pixels per frame, including Link's base walking speed.
const int ICE_MAX_TRACT = 1.5;//Max speed on ice in pixels per frame, including Link's base walking speed.
const int ICE_DEF_ACCEL = 0.015;//Default acceleration if none defined, in portion of current speed.
const int ICE_DEF_DECEL = 0.010;//Default deceleration if none defined, in portion of current speed. Never >1. 1 = dead stop.
const int I_TRACT_BOOTS_1 = 154;//Item ID that will cause ice to be half as slippery.
const int I_TRACT_BOOTS_2 = 155;//Item ID that will cause ice to not be slippery.
const int ICE_MIN_ACCEL = 1;

generic script icePhysics
{
	int old_step, is_onice = 0;
	bool isOnIce()
	{
		int ul = GetLayerComboT(0,ComboAt(Hero->X,Hero->Y));
		int ur = GetLayerComboT(0,ComboAt(Hero->X+15,Hero->Y));
		int bl = GetLayerComboT(0,ComboAt(Hero->X,Hero->Y+15));
		int br = GetLayerComboT(0,ComboAt(Hero->X+15,Hero->Y+15));
		return (ul==CT_ICE||ur==CT_ICE||bl==CT_ICE||br==CT_ICE);
	}

	void run(int accel, int decel)
	{
		if(accel==0)
			accel=ICE_DEF_ACCEL;
		if(decel==0)
			decel=ICE_DEF_DECEL;
		int xaccel=0;
		int yaccel=0;
		int xdecel=0;
		int ydecel=0;
		int Vx = 0;
		int Vy = 0;
		bool onIce = false;
		bool noTract = true;
		int scrn = 0;
		float upmult = 1, downmult = 1, leftmult = 1, rightmult = 1;
		int max = ICE_MAX;
		while(true)
		{
			while(Screen->ShowingMessage || Game->Scrolling[SCROLL_DIR] > -1)
				Waitframe();
			unless(Hero->Item[I_TRACT_BOOTS_2])
			{
				if(noTract && Hero->Item[I_TRACT_BOOTS_1])
				{
					CONFIG TRACT_SPEEDUP = 4, TRACT_SLOWDOWN = 1/TRACT_SPEEDUP;
					rightmult = (Vx < 1.5) ? TRACT_SPEEDUP : TRACT_SLOWDOWN;
					leftmult = (Vx > -1.5) ? TRACT_SPEEDUP : TRACT_SLOWDOWN;
					downmult = (Vy < 1.5) ? TRACT_SPEEDUP : TRACT_SLOWDOWN;
					upmult = (Vy > -1.5) ? TRACT_SPEEDUP : TRACT_SLOWDOWN;
					max = ICE_MAX_TRACT;
					noTract = false;
				}
				else if(!noTract && !Hero->Item[I_TRACT_BOOTS_1])
				{
					upmult = downmult = leftmult = rightmult = 1;
					max = ICE_MAX;
					noTract = true;
				}
				if(!onIce)
				{
					Vx=0;
					Vy=0;
				}
				if(!onIce && isOnIce()) //Link has just stepped onto ice
				{
					if(Hero->InputDown)
						Vy+=Hero->Step/100;
					if(Hero->InputUp)
						Vy-=Hero->Step/100;
					if(Hero->InputRight)
						Vx+=Hero->Step/100;
					if(Hero->InputLeft)
						Vx-=Hero->Step/100;
					if(Vx && Vy)
					{
						Vx /= 4;
						Vy /= 4;
					}
					else
					{
						Vx /= 2;
						Vy /= 2;
					}
					is_onice = 2;
					old_step = Hero->Step;
					Hero->Step = 0;
				}
				else if(onIce)
				{
					int xm = Max(ICE_MIN_ACCEL,Abs(Vx));
					int ym = Max(ICE_MIN_ACCEL,Abs(Vy));
					xaccel = accel * xm;
					xdecel = decel * xm;
					yaccel = accel * ym;
					ydecel = decel * ym;
					if(Abs(Vy)<max)
					{
						if(Hero->InputDown)
							Vy+=yaccel*downmult;
						if(Hero->InputUp)
							Vy-=yaccel*upmult;
					}
					if(Abs(Vx)<max)
					{
						if(Hero->InputRight)
							Vx+=xaccel*rightmult;
						if(Hero->InputLeft)
							Vx-=xaccel*leftmult;
					}
					Vx = Clamp(Vx, -max, max);
					Vy = Clamp(Vy, -max, max);
					Hero->MoveXY(Vx,Vy);
					if(Vx > 0 && !Hero->InputRight)
						Vx-=xdecel;
					if(Vx < 0 && !Hero->InputLeft)
						Vx+=xdecel;
					if(Vy > 0 && !Hero->InputDown)
						Vy-=ydecel;
					if(Vy < 0 && !Hero->InputUp)
						Vy+=ydecel;
				}
				if(Abs(Vy)<0.01) Vy=0;
				if(Abs(Vx)<0.01) Vx=0;
				onIce = isOnIce();
			}
			else onIce = false;
			if(is_onice && !onIce)
			{
				Hero->Step = old_step;
				is_onice = 0;
			}
			Waitframe();
		}
	}
}

ffc script trading
{
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Plays a string on interaction. Can also trigger secrets, either permanently or temporarily.                                  //
	//D0: Number of string to display after beginning string, before ending string                                                              //
	//D1: Button to press to trigger the message display. 0=A, 1=B, 2=L, 3=R.                                                                   //
	//D2: Set to 1 if using Large Link option.                                                                                                  //
	//D3: Set to 1 if you want the message to be readable from any side, 0 if from the bottom only.                                             //
	//D4: Item you want to be deducted to trigger flag. 0=Bomb, 1=Arrow, 2=Rupees, 3=SBombs, 4=Life, 5=Magic, 6=RedPot, 7=GreenPot, 8=BluePot   //
	//---To take an inventory item, take the item's ID number and add 1000 to it. In this case, amount will do nothing.                         //
	//D5: Amount of item to deduct. Does not apply to potion items.                                                                             //
	//D6: Number of flag to replace with a different combo when triggered.                                                                      //
	//D7: Combo ID to be placed in place of every flag of the D6 type.                                                                          //
	//"Messages disappear" and "Messages freeze all action" quest rules should be set. "Run script at screen init" should be set.               //
	//WARNING: Uses the first X Screen->D[] variables, X being the number of this script placed on the same screen.                             //
	// AUTHOR: Emily                                                 //                                               VERSION: 1.0 (1/22/2018) //
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	const int startMsg = 25; //Set to 0 for no start message (Message displayed before every trade message)
	const int endMsgYes = 34; //Set to 0 for no confirm message (Message displayed if trade is successful)
	const int endMsgNo = 0; //Set to 0 for no deny message (Message displayed if trade in unsuccessful)
	const int afterTriggered = 34; //Set to 0 for no message after trigger (Message displayed if message read again after successful trade)
    void run(int m,int input,bool largeHitbox,bool anySide, int itemId, int amountOfItem, int comboFlag, int comboReplace){
        int loc = ComboAt(this->X,this->Y);
		checkTrigger(afterTriggered, input, largeHitbox, anySide, comboFlag, comboReplace, loc);
        while(true){
            while(!AgainstComboBase(loc,largeHitbox,anySide) || !SelectPressInput(input)) Waitframe();
            SetInput(input,false);
			if(startMsg!=0){Screen->Message(startMsg);Waitframe();}
            Screen->Message(m);
            Waitframe();
			if(TakeItem(itemId,amountOfItem)){
				if(endMsgYes!=0){Screen->Message(endMsgYes);Waitframe();}
				triggerCombo(comboFlag, comboReplace, true, false);
				checkTrigger(afterTriggered, input, largeHitbox, anySide, comboFlag, comboReplace, loc);
			} else {
				if(endMsgNo!=0){Screen->Message(endMsgNo);Waitframe();}
			}
			Waitframe();
        }
    }
    bool AgainstComboBase(int loc, bool largeHitbox, bool anySide){
		if(largeHitbox && !anySide){
			return Hero->Z == 0 && (Hero->Dir == DIR_UP && Hero->Y == ComboY(loc)+16 && Abs(Hero->X-ComboX(loc)) < 8);
		} else if (!largeHitbox&&!anySide){
			return Hero->Z == 0 && (Hero->Dir == DIR_UP && Hero->Y == ComboY(loc)+8 && Abs(Hero->X-ComboX(loc)) < 8);
		} else if (largeHitbox && anySide){
			return Hero->Z == 0 && ((Hero->Dir == DIR_UP && Hero->Y == ComboY(loc)+16 && Abs(Hero->X-ComboX(loc)) < 8)||(Hero->Dir == DIR_DOWN && Hero->Y == ComboY(loc)-16 && Abs(Hero->X-ComboX(loc)) < 8)||(Hero->Dir == DIR_LEFT && Hero->X == ComboX(loc)+16 && Abs(Hero->Y-ComboY(loc)) < 8)||(Hero->Dir == DIR_RIGHT && Hero->X == ComboX(loc)-16 && Abs(Hero->Y-ComboY(loc)) < 8));
		} else if (!largeHitbox && anySide){
			return Hero->Z == 0 && ((Hero->Dir == DIR_UP && Hero->Y == ComboY(loc)+8 && Abs(Hero->X-ComboX(loc)) < 8)||(Hero->Dir == DIR_DOWN && Hero->Y == ComboY(loc)-16 && Abs(Hero->X-ComboX(loc)) < 8)||(Hero->Dir == DIR_LEFT && Hero->X == ComboX(loc)+16 && Abs(Hero->Y-ComboY(loc)) < 8)||(Hero->Dir == DIR_RIGHT && Hero->X == ComboX(loc)-16 && Abs(Hero->Y-ComboY(loc)) < 8));
		} else {return false;}
    }
	
	void triggerCombo(int flag, int combo, bool secretSFX, bool fromCheck){
		for(int i = 0;i<=175;i++){
			if(ComboFI(i,flag)){
				Screen->ComboD[i]=combo;
			}
		}
		if(secretSFX)Game->PlaySound(SFX_SECRET);
		if(fromCheck)return;
		for(int i = 0;i<8;i++){
			if(Screen->D[i]==0){
				Screen->D[i]=1000+flag;
				return;
			}
		}
		
	}
	
	void checkTrigger(int m,int input,bool largeHitbox,bool anySide, int flag, int combo, int loc){
		for(int i = 0;i<8;i++){
			if(Screen->D[i]==(1000+flag)){
				triggerCombo(flag, combo, false, true);
				if(m==0)Quit();
				while(true){
					while(!AgainstComboBase(loc,largeHitbox,anySide) || !SelectPressInput(input)) Waitframe();
					SetInput(input,false);
					Screen->Message(m);
					Waitframe();
				}
			}
		}
	}
	
	bool TakeItem(int itemId, int amnt){
		//0=bombs,1=arrows,2=rupees,3=superbombs,4=hearts,5=magic //from emptyBottles script: 6=redPotion, 7=greenPotion, 8=bluePotion
		if(itemId==0){
			if(Game->Counter[CR_BOMBS]>=amnt){
				Game->Counter[CR_BOMBS]-=amnt;
				return true;
			} else{return false;}
		} else if(itemId==1){
			if(Game->Counter[CR_ARROWS]>=amnt){
				Game->Counter[CR_ARROWS]-=amnt;
				return true;
			} else{return false;}
		} else if(itemId==2){
			if(Game->Counter[CR_RUPEES]>=amnt){
				Game->Counter[CR_RUPEES]-=amnt;
				return true;
			} else{return false;}
		} else if(itemId==3){
			if(Game->Counter[CR_SBOMBS]>=amnt){
				Game->Counter[CR_SBOMBS]-=amnt;
				return true;
			} else{return false;}
		} else if(itemId==4){
			if(Game->Counter[CR_LIFE]>=amnt){
				Game->Counter[CR_LIFE]-=amnt;
				return true;
			} else{return false;}
		} else if(itemId==5){
			if(Game->Counter[CR_MAGIC]>=amnt){
				Game->Counter[CR_MAGIC]-=amnt;
				return true;
			} else{return false;}
		} else if(itemId==6){
			return ClearBottle(BS_POTIONRED);
		} else if(itemId==7){
			return ClearBottle(BS_POTIONGREEN);
		} else if(itemId==8){
			return ClearBottle(BS_POTIONBLUE);
		} else if(itemId>1000){
			if(Hero->Item[itemId-1000]){
				Hero->Item[itemId-1000]=false;
				return true;
			} else{return false;}
		}
	}
}

ffc script playString
{
	void run(int str, bool secret, bool perm, bool once)
	{
		while(Hero->Action==LA_SCROLLING) Waitframe();
		Waitframes(2);
		if(!(Screen->ExState[31]&&once))
			Screen->Message(str);
		else Quit();
		Waitframes(5);
		if(once) Screen->ExState[31] = true;
		if(secret)
		{
			Screen->TriggerSecrets();
			if(perm)
				Screen->State[ST_SECRET] = true;
		}
	}
}

item script itemPlayString
{
	void run(int str)
	{
		Screen->Message(str);
	}
}

ffc script stepTrigger
{
	void run(int num, int max, bool perm)
	{
		while(true)
		{
			if(Abs(Hero->X-this->X)<=8 && Abs(Hero->Y-this->Y)<=8)
			{
				if(num!=1&&num!=max)
				{
					if(Hero->Misc[7]==num-1||Hero->Misc[7]==num)
						Hero->Misc[7]=num;
					else
						Hero->Misc[7]=0;
				}
				else if(num==1)
					Hero->Misc[7]=1;
				else if(num==max)
				{
					if(Hero->Misc[7]==num-1)
					{
						Hero->Misc[7]=0;
						Screen->TriggerSecrets();
						if(perm)
							Screen->State[ST_SECRET]=true;
						Game->PlaySound(SFX_SECRET);
					}
					else Hero->Misc[7]=0;
				}
			}
			Waitframe();
		}
	}
}

ffc script TriforceCheck
{
	void run(int triforce, int mode)
	{
		if(NumTriforcePieces()>=triforce)
		{
			if(mode==0)
				Screen->TriggerSecrets();
			else if(mode==1)
			{
				Screen->TriggerSecrets();
				Screen->State[ST_SECRET] = true;
			}
			else if(mode==2)
				for(n : Screen->NPCs)
					n->HP = 0;
		}
	}
}

}

