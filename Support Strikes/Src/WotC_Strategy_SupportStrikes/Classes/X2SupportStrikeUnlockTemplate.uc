class X2SupportStrikeUnlockTemplate extends X2SoldierUnlockTemplate;

// Does not actually grant the ability to the units. Only used for localization purposes
var name AbilityName;

function OnSoldierUnlockPurchased(XComGameState NewGameState)
{
	local XComGameStateHistory								History;
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;
	local XComGameState_SupportStrike_Tactical				StrikeTactical;

	History = `XCOMHISTORY;

	SupportStrikeMgr = XComGameState_SupportStrikeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));
	SupportStrikeMgr = XComGameState_SupportStrikeManager(NewGameState.ModifyStateObject(class'XComGameState_SupportStrikeManager', SupportStrikeMgr.ObjectID));

	SupportStrikeMgr.PurchasedSupportStrikes.AddItem(self.DataName);

	//Special requirement for Helidrop in
	if (self.DataName == 'GTSUnlock_Airborne_Def_HeliDropIn_T1')
	{
		//Create a new tactical object and initialize it
		StrikeTactical = XComGameState_SupportStrike_Tactical(NewGameState.CreateNewStateObject(class'XComGameState_SupportStrike_Tactical'));
		StrikeTactical.InitializeGameState(NewGameState);
		SupportStrikeMgr.TacticalGameState = StrikeTactical.GetReference();
	}
}

function string GetSummary() 
{
	local X2AbilityTag AbilityTag;
	local string RetStr;

	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = self;
	RetStr = `XEXPAND.ExpandString(Summary);
	AbilityTag.ParseObj = none;
	return RetStr;
}

function bool ValidateTemplate(out string strError)
{
	local X2SoldierClassTemplateManager SoldierTemplateMan;
	local name SoldierClass;

	if (AllowedClasses.Length == 0 && !bAllClasses)
	{
		strError = "no AllowedClasses specified, and bAllClasses is false";
		return false;
	}
	SoldierTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();	
	foreach AllowedClasses(SoldierClass)
	{
		if (SoldierTemplateMan.FindSoldierClassTemplate(SoldierClass) == none)
		{
			strError = "references unknown soldier class template" @ SoldierClass;
			return false;
		}
	}
	if (class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName) == none)
	{
		strError = "references unknown ability template" @ AbilityName;
		return false;
	}
	return super.ValidateTemplate(strError);
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	bShouldCreateDifficultyVariants = true
}