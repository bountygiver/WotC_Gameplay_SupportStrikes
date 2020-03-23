class UISL_TacticalHUD_SupportStrikes extends UIScreenListener;

event OnInit(UIScreen Screen) {
    if (UITacticalHUD(Screen) != none) {
		class'UIPopups_SupportStrikes'.static.GetOrCreate();
    }
}