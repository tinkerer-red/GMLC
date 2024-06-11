/// @description The Whole Game Is Just In This Script. Somehow.
function MathewBrown() {

	randomize();

	if !ds_exists(0, ds_type_list) {
	    var game_data = ds_list_create();
    
	    var current_event = 0;
    
	    var option = -1;
    
	    var public = 50;
	    var alien = 50;
	    var energy = 50;
	    var money = 50;
	    var army = 50;
    
	    var time = 1;
    
	    var start = true;
    
	    var end_game = false;
    
	    ds_list_add(game_data, current_event, option, public, alien, army, money, energy, time, start, end_game);
    
	    var bg_color = make_color_rgb(30, 35, 100)
    
	    __background_set_colour( bg_color );
	    __background_set_showcolour( true );
	}
	 // Create the variables from the DS_list
	var current_event = ds_list_find_value(0, 0);
    
	var option = ds_list_find_value(0, 1);

	var public = ds_list_find_value(0, 2);
	var alien = ds_list_find_value(0, 3);
	var army = ds_list_find_value(0, 4);
	var money = ds_list_find_value(0, 5);
	var energy = ds_list_find_value(0, 6);

	var time = ds_list_find_value(0, 7);

	var start = ds_list_find_value(0, 8);
	var end_game = ds_list_find_value(0, 9);



	var event;
	// Intro
	event[0] = "Welcome! There's been a bit of a crisis, and you've been selected to look after this city until a connection with the central system can be re-established. There's a lot to go over, but we should start with the controls, so you can actually make it to the next message. Down in the bottom right there's four options you can select. They're all the same for now, but they'll be really important once you get started. You select them with the arrow keys. You should be able to figure out which key selects which option, otherwise we may have chosen our leader poorly...";
	event[1] = "Very good! You know how to follow simple instructions. There's going to be a lot more thought involved once I'm done explaining everything though. These message you're seeing now, those are going to be replaced by message and reports from your citizens, the races of nearby planets, your army, and various other parties. Usually about crisises. Or demands. Very rarely about good things, that much I can say for sure.";
	event[2] = "The choice presented there was an illusion. You'd have gotten this exact response either way. But later it's going to have big impact. You see those bars on the left? Those represent how well things are going. How well liked you are by your people, how pleased with you the Ventori Nation (those guys are a nearby race of aliens with enough power to end your existence effortlessly if they ever deem you despicable enough), how well-suited your military is to fight off threats from other races you might actually stand a chance against, how much money you have to get all of this done with, and how much power the city has to operate with. Because modern life uses up a LOT of energy, trust me. Those people back in the 21st century thought they had it bad.";
	event[3] = "Nope. And a lot of that explanation was probably fairly straight-forward, but just covering all my bases here, in case you're an idiot. Hoepfully not, since our entire future rests in your hands. Anyhoo, how you choose to handle the various situations as they're thrown at you will affect those bars there. The majority of actions will make at least one go up and at least one go down, but there might be a few exceptions. And if any of those bars runs out, then you lose, and your city falls into ruin in one of several different ways.";
	event[4] = "Sounds fun, right? Don't worry though, if you can manage to keep everything afloat for a whole year, the city will be able to connect back to the central system, and you'll win the game. Because the central system has enough resources and whatnot to solve all of these issues a lot better than you can, so everything will be fine after that. Unless you play the game again. Then I guess there's another crisis.";
	event[5] = "So let's get started! I'll give you an actually relevant choice this time to get you started off. Pick one of the stats to get a small starting bonus before you're thrown into the real game, courtesy of yours truely. But you can't pick the Ventori. I could make up some kind of reasonable sounding excuse, like saying I don't have the power to affect things outside your city, but let's be real here. The programmer didn't put in room for more than four options, so I had to leave SOMETHING out. So make your choice, we'll send you back through the fourth wall, and get this game started!";
	// Power plant failure
	event[6] = "Technician: There’s been a system failure at one of the central power plants! We need extra funding to fix the issue, without this power plant the whole city could be at risk.";
	// Army raise
	event[7] = "General: The men are demanding a raise! Some of them are threatening strike, and they're rallying the public onto their side, saying your wages are unfair. I worry what might happen if we ignore this...";
	// Charity for a disaster
	event[8] = "Counselor: Sir, a lot of people have lost have their homes and possesions due to disasters caused by recent malfunctions in the nature regulators. The regulaters have been fixed now, but I think if we raise a fund for these people, it could go a long way towards helping your public image.";
	// Rogue A.I.
	event[9] = "Scientist: Sir, this is terrible! There's been a problem at one of our research labs, an A.I. has gone rogue and is trying to kill all the scientists! I don't know how she got neurotoxin, but none of us can outsmart her...";
	// Ventori Crime
	event[10] = "Counselor: This is bad... There's overwhelming evidence pointing towards a promonent member of the Ventori nation as the perpetrator of a recent murder. There's a public outcry for us to do something, but if we prosecute him ourselves, the Ventori won't be pleased...";
	// Terth Demands
	event[11] = "General: The Terth armies are demanding that we pay them a large sum of money, or they'll attack us! The Terth are a powerful warrior race, if we fight we could lose a lot of our army. What should we do?";
	// Speed Enhancement
	event[12] = "Scientist: Sir, the men at the lab have developed something amazing. It's a speed increasing stimulant we believe will have amazing wide-spread uses. We're calling it the Speed Enhancing Genitic Additive. So far it's been tested to have amazing results in hedgehogs, and while some people oppose it, we believe human testing to be the next major step. What do you say?";
	// Power Formula
	event[13] = "Scientist: We've developed a new material we could add to the energy formula to increase power production significatly. But some early tests suggest that it could have potential dangers involved.";
	// Terth War
	event[14] = "General: Dire news sir! The bloodthirsty Terth have declared war! We have reports suggesting they're planning an attack right now!";
	// Hospital Space
	event[15] = "Doctor: Between recent disasters and outbreaks of disease, our hospitals are running out of space for everyone. It's becoming an increasingly big problem, something has to be done.";
	// Ventori Gift
	event[16] = "Ventori Ambassador: Our people see potintial in yours, and as such we would like to offer you a gift to help you get by. My understanding is that some of your people don't trust help from our race, but I think it would go towards a mutual respect in the long term.";
	// Sonic Tech
	event[17] = "Scientist: We've prototyped an idea for poerful new sonic technology, but we need a focus to finish development. What should we apply this tech towards?";
	// Stolen Money
	event[18] = "Counselor: Sir, someone hacked our account last night, a lot of our credits are gone! We have to do something!";
	// Fugitives
	event[19] = "Counselor: We've recived word that a criminal we've beign trying to track down has gone into hiding on a lightning-bug class cargo ship. We could track it down and bring them in, but one of the crew members, Cayne Jobb, is a local hero. If we arrest them, there could be outrage.";
	// Filler
	event[20] = "Scientist: The programmer is running out of time! What do we do?";
	// Jerk Guy
	event[21] = "Counselor: A well liked celebrity has said something on TV that offended the Ventori. They're quite anrgy, but so might the people be if we don't act carefully.";


	var choices;
	// Intro
	choices[0, 0] = "Okay.";
	choices[0, 1] = "Okay.";
	choices[0, 2] = "Okay.";
	choices[0, 3] = "Okay.";
	choices[1, 0] = "Great...";
	choices[1, 1] = "I never signed up for this...";
	choices[1, 2] = "And then what?";
	choices[1, 3] = "Why did you pick me again?";
	choices[2, 0] = "So it still doesnt' matter what I pick?";
	choices[2, 1] = "Does what I pick here even matter?";
	choices[2, 2] = "Do these choices mean anything yet?";
	choices[2, 3] = "Why are these even different if the effect is the same?";
	choices[3, 0] = "Sounds unpleasant...";
	choices[3, 1] = "I think I'll be fine.";
	choices[3, 2] = "Is there any way to win?";
	choices[3, 3] = "I'm just picking something, I know these options still don't matter.";
	choices[4, 0] = "Sit here and do nothing.";
	choices[4, 1] = "Option B";
	choices[4, 2] = "Option C";
	choices[4, 3] = "Option D";
	choices[5, 0] = "Public Opinion";
	choices[5, 1] = "Army Strength";
	choices[5, 2] = "Availible Funds";
	choices[5, 3] = "City Energy Level";
	// Power plant failure
	choices[6, 0] = "We don’t have the money. We’ll have to run on reserve power until we can save up to fix it.";
	choices[6, 1] = "We’ll spare what we can. Patch it up as best you can.";
	choices[6, 2] = "Spare no expense! Fix it as fast as you can, and put in extra failsafes to prevent future incidents.";
	choices[6, 3] = "Make arrangements with the aliens. Our people will lose the work, but they should get it running for us for less cost than we can ourselves.";
	// Army raise
	choices[7, 0] = "No! I won't give into such demands. we already pay them what we can afford. Do what you can to mitigate the damage, but their way stays the same.";
	choices[7, 1] = "Give them a bonus to appease the populace. It should be enough to make the problem fade.";
	choices[7, 2] = "Fine, increase their wages. But I expect them to be the best if I'm going to pay them like it.";
	choices[7, 3] = "They're right, increase the wages of all our employees, and give more benifits to the lower class. It'll cost a lot, but we can turn this situation around for our benifit.";
	// Charity for a disaster
	choices[8, 0] = "A wise desicion I think. Put together to help them as soon as possible.";
	choices[8, 1] = "Of course! We should even give a generous donation ourselves, that should go a long way towards both our image and helping these people get back on their feet.";
	choices[8, 2] = "Set up a fund for the city as a whole, using these disasters as a focal point to encourage donations. I'm sure it'll upset some, but the money we'll raise will be worth it.";
	choices[8, 3] = "Send out a public message of condolances, and encouraging others to help. It's the most help we can offer at low cost.";
	// Rogue A.I
	choices[9, 0] = "Get everyone out that you can and seal off the research lab! We'll lose a lot of valuable investments, but as long as no idiots stumble down there, everyone should be safe.";
	choices[9, 1] = "Try to see if you can find a way to regulate her behaviour. People might not trust her anymore, but if we can prevent her from using neurotoxin or dampen her intelligence a bit, she could still prove valuable.";
	choices[9, 2] = "She's killing people? Re-purpose her for the military! It might not be entirely ethical, but this could be a militaristic breakthrough!";
	choices[9, 3] = "Send the military in if you have to to get her, and then set up a showmatch between her and the best computer the Ventori have to offer. It'll cost a lot, but I think a friendly contest should please both groups.";
	// Ventori Crime
	choices[10, 0] = "They won't be happy, but we have to. We'll have riots if we don't do something, and we can't let them think we'll sit here and let them bypass our laws. Prosecute him the same as one of own citizens.";
	choices[10, 1] = "Urge the Ventori to do something. He hasn't broken any of their laws, but insist that for the good of our nations' relations they have to.";
	choices[10, 2] = "Give him back to the Ventori. He's their citizen, and we can't risk the provocation from treating him as anything else. Do what you can to quell the public outrage, it's our only option.";
	choices[10, 3] = "There has to be some way to buy our way out of this... See who you can bribe to make this problem disappear.";
	// Terth Demands
	choices[11, 0] = "Pay them. I hate to give into demands, but we can't afford a war right now.";
	choices[11, 1] = "Arrange a show of display of military prowess. It might cost even more than they're demanding, but it should help dissuade other's from thinking we're an easy target.";
	choices[11, 2] = "We don't take demands, or threats. Set up defenses, if they carry out that threat we'll be the ones takign their riches.";
	choices[11, 3] = "The Ventori aren't great friends with the Terth, are they? See if you can persuade them to intervene.";
	// Speed Enhancement
	choices[12, 0] = "Human testing? No, that isn't safe enough, I can't agree to that.";
	choices[12, 1] = "Spend what you need to test it as thoroughly as possible before using it on people.";
	choices[12, 2] = "Send it directly to the military. It might take some trial and error, but this will give our army the edge it needs!";
	choices[12, 3] = "It's safe for the hedgehogs, right? Send it straight to market while the hype is still high. We'll split the profits.";
	// Power Formula
	choices[13, 0] = "Use it anyway. We need the extra energy to keep this city running.";
	choices[13, 1] = "Spend extra time and money developing a safer version. Then we can use it to maximum effect without worry.";
	choices[13, 2] = "What kind of dangers? See if you can find a way to weaponize it instead.";
	choices[13, 3] = "No, we can't take the risk. Keep the power plants running on the old formula.";
	// Terth War
	choices[14, 0] = "Send out the army to intercept them! We have to cut htem off before they reach our people whatever the cost.";
	choices[14, 1] = "Set up defenses around the city. Bringing them closer to home puts citizens at risk, but it should give our army the advantage.";
	choices[14, 2] = "Send the dimplomats, see if we can negotiate terms. And send credits with them.";
	choices[14, 3] = "Can you increase the power output to our shielding? We should be able to out-siege them with minimal casualties.";
	// Hospital Space
	choices[15, 0] = "Fund an expansion for the hospitals we already have. That should be enough to stave off the issue.";
	choices[15, 1] = "Build a new, state-of-the-art hospital, with all the latest and highest powered facilities.";
	choices[15, 2] = "Build a specialized hospital for the army. That should take a little of the laod off the others, as well as providing our army with stronger support.";
	choices[15, 3] = "The Ventori wanted to learn more about humans, right? Send people there for medical aid. The Ventori are smart, they'll probably be able to help most of them.";
	// Ventori Gift
	choices[16, 0] = "A gift of energy would be greatly appriciated. Our society uses a lot of it.";
	choices[16, 1] = "Could you perhaps spare some credits? We're running low.";
	choices[16, 2] = "Would a gift to our army be too much to ask? We could use the aid against other, less civilized races.";
	choices[16, 3] = "I'm sorry. I would love to accept, but I don't feel it would sit well with my people right now.";
	// Sonic Tech
	choices[17, 0] = "Sonic weaponry sounds rather powerful, see if you can weaponize it.";
	choices[17, 1] = "New, higher quality sound systems perhaps? It might not sound like the most practical use, but anything to keep people happy goes a long way.";
	choices[17, 2] = "You know what I think could be sonic? Screwdivers. Make it happen, give them to our power plant engineers. I'm sure they could put those to good use.";
	choices[17, 3] = "Sell the tech to the highest bidder, let them use it as they see fit.";
	// Stolen Money
	choices[18, 0] = "Send our army to track down this theif. We can't afford that heavy a loss of funds.";
	choices[18, 1] = "Offer half of the stolen money as a reward to whoever can track the theif down. We'll still be a notable amount of money, but it's better than losing all of it.";
	choices[18, 2] = "Raise taxes to replace it, we don't have the resources to track the thief down.";
	choices[18, 3] = "Ask the Ventori for help. The people will doubtless be angry about allowing the Ventori into our justice system, but we need their help with this.";
	// Fugitives
	choices[19, 0] = "If they're harboring fugitives, bring them in, local hero or not.";
	choices[19, 1] = "We don't want to risk angering the people. Let them be.";
	choices[19, 2] = "They're managing to keep fugitives hidden from us? See if you can hire them!";
	choices[19, 3] = "But a bounty out discretely, see if we can capture the fugitives under the public's notice.";
	// Filler
	choices[20, 0] = "Put in stupid filler events like this one. People might not like it, but it's better than nothing.";
	choices[20, 1] = "Pull an all-nighter to get more content in.";
	choices[20, 2] = "Bribe someone to extend the deadline!";
	choices[20, 3] = "Ask the Ventori, they solve evrything, right?";
	// Jerk Guy
	choices[21, 0] = "Ignore it. It might not be nice, but he can say what he wants to.";
	choices[21, 1] = "Publicly apologize to the Ventori, and claim no agreement with that stupid celebrity. If he's going to be a jerk, we won't support him.";
	choices[21, 2] = "Descretely apologize to the Ventori. They might still be angered that we won't publicly denouce these harsh words, but it should help patch the damage.";
	choices[21, 3] = "Patch the damage with money. That usually works.";


	var e_public;
	var e_alien;
	var e_army;
	var e_money;
	var e_energy;

	//Intro
	e_public[0,0] = 0;
	e_alien[0,0] = 0;
	e_army[0,0] = 0;
	e_money[0,0] = 0;
	e_energy[0,0] = 0;
	e_public[0,1] = 0;
	e_alien[0,1] = 0;
	e_army[0,1] = 0;
	e_money[0,1] = 0;
	e_energy[0,1] = 0;
	e_public[0,2] = 0;
	e_alien[0,2] = 0;
	e_army[0,2] = 0;
	e_money[0,2] = 0;
	e_energy[0,2] = 0;
	e_public[0,3] = 0;
	e_alien[0,3] = 0;
	e_army[0,3] = 0;
	e_money[0,3] = 0;
	e_energy[0,3] = 0;

	e_public[1,0] = 0;
	e_alien[1,0] = 0;
	e_army[1,0] = 0;
	e_money[1,0] = 0;
	e_energy[1,0] = 0;
	e_public[1,1] = 0;
	e_alien[1,1] = 0;
	e_army[1,1] = 0;
	e_money[1,1] = 0;
	e_energy[1,1] = 0;
	e_public[1,2] = 0;
	e_alien[1,2] = 0;
	e_army[1,2] = 0;
	e_money[1,2] = 0;
	e_energy[1,2] = 0;
	e_public[1,3] = 0;
	e_alien[1,3] = 0;
	e_army[1,3] = 0;
	e_money[1,3] = 0;
	e_energy[1,3] = 0;

	e_public[2,0] = 0;
	e_alien[2,0] = 0;
	e_army[2,0] = 0;
	e_money[2,0] = 0;
	e_energy[2,0] = 0;
	e_public[2,1] = 0;
	e_alien[2,1] = 0;
	e_army[2,1] = 0;
	e_money[2,1] = 0;
	e_energy[2,1] = 0;
	e_public[2,2] = 0;
	e_alien[2,2] = 0;
	e_army[2,2] = 0;
	e_money[2,2] = 0;
	e_energy[2,2] = 0;
	e_public[2,3] = 0;
	e_alien[2,3] = 0;
	e_army[2,3] = 0;
	e_money[2,3] = 0;
	e_energy[2,3] = 0;

	e_public[3,0] = 0;
	e_alien[3,0] = 0;
	e_army[3,0] = 0;
	e_money[3,0] = 0;
	e_energy[3,0] = 0;
	e_public[3,1] = 0;
	e_alien[3,1] = 0;
	e_army[3,1] = 0;
	e_money[3,1] = 0;
	e_energy[3,1] = 0;
	e_public[3,2] = 0;
	e_alien[3,2] = 0;
	e_army[3,2] = 0;
	e_money[3,2] = 0;
	e_energy[3,2] = 0;
	e_public[3,3] = 0;
	e_alien[3,3] = 0;
	e_army[3,3] = 0;
	e_money[3,3] = 0;
	e_energy[3,3] = 0;

	e_public[4,0] = 0;
	e_alien[4,0] = 0;
	e_army[4,0] = 0;
	e_money[4,0] = 0;
	e_energy[4,0] = 0;
	e_public[4,1] = 0;
	e_alien[4,1] = 0;
	e_army[4,1] = 0;
	e_money[4,1] = 0;
	e_energy[4,1] = 0;
	e_public[4,2] = 0;
	e_alien[4,2] = 0;
	e_army[4,2] = 0;
	e_money[4,2] = 0;
	e_energy[4,2] = 0;
	e_public[4,3] = 0;
	e_alien[4,3] = 0;
	e_army[4,3] = 0;
	e_money[4,3] = 0;
	e_energy[4,3] = 0;

	e_public[5,0] = 5;
	e_alien[5,0] = 0;
	e_army[5,0] = 0;
	e_money[5,0] = 0;
	e_energy[5,0] = 0;
	e_public[5,1] = 0;
	e_alien[5,1] = 0;
	e_army[5,1] = 5;
	e_money[5,1] = 0;
	e_energy[5,1] = 0;
	e_public[5,2] = 0;
	e_alien[5,2] = 0;
	e_army[5,2] = 0;
	e_money[5,2] = 5;
	e_energy[5,2] = 0;
	e_public[5,3] = 0;
	e_alien[5,3] = 0;
	e_army[5,3] = 0;
	e_money[5,3] = 0;
	e_energy[5,3] = 5;

	//Power plant failure
	e_public[6,0] = -3;
	e_alien[6,0] = 0;
	e_army[6,0] = 0;
	e_money[6,0] = 2;
	e_energy[6,0] = -10;
	e_public[6,1] = 0;
	e_alien[6,1] = 0;
	e_army[6,1] = 0;
	e_money[6,1] = -3;
	e_energy[6,1] = -4;
	e_public[6,2] = 2;
	e_alien[6,2] = 0;
	e_army[6,2] = 0;
	e_money[6,2] = -8;
	e_energy[6,2] = 3;
	e_public[6,3] = -5;
	e_alien[6,3] = 5;
	e_army[6,3] = 0;
	e_money[6,3] = -2;
	e_energy[6,3] = 2;
	// Army raise
	e_public[7,0] = -5;
	e_alien[7,0] = 0;
	e_army[7,0] = -10;
	e_money[7,0] = 5;
	e_energy[7,0] = 0;
	e_public[7,1] = 5;
	e_alien[7,1] = 0;
	e_army[7,1] = -5;
	e_money[7,1] = -3;
	e_energy[7,1] = 0;
	e_public[7,2] = 0;
	e_alien[7,2] = 0;
	e_army[7,2] = 10;
	e_money[7,2] = -8;
	e_energy[7,2] = 0;
	e_public[7,3] = 10;
	e_alien[7,3] = 0;
	e_army[7,3] = 5;
	e_money[7,3] = -15;
	e_energy[7,3] = 0;
	// Chairity for a disaster
	e_public[8,0] = 5;
	e_alien[8,0] = 0;
	e_army[8,0] = 0;
	e_money[8,0] = -3;
	e_energy[8,0] = 0;
	e_public[8,1] = 15;
	e_alien[8,1] = 0;
	e_army[8,1] = 0;
	e_money[8,1] = -10;
	e_energy[8,1] = 0;
	e_public[8,2] = -5;
	e_alien[8,2] = 0;
	e_army[8,2] = 0;
	e_money[8,2] = 10;
	e_energy[8,2] = 0;
	e_public[8,3] = 1;
	e_alien[8,3] = 0;
	e_army[8,3] = 0;
	e_money[8,3] = -2;
	e_energy[8,3] = 0;
	// Rogue A.I.
	e_public[9,0] = 3;
	e_alien[9,0] = 0;
	e_army[9,0] = 0;
	e_money[9,0] = -3;
	e_energy[9,0] = -3;
	e_public[9,1] = -5;
	e_alien[9,1] = 0;
	e_army[9,1] = 0;
	e_money[9,1] = -5;
	e_energy[9,1] = 10;
	e_public[9,2] = -10;
	e_alien[9,2] = 0;
	e_army[9,2] = 15;
	e_money[9,2] = -5;
	e_energy[9,2] = 0;
	e_public[9,3] = 5;
	e_alien[9,3] = 5;
	e_army[9,3] = 0;
	e_money[9,3] = -8;
	e_energy[9,3] = 0;
	// Ventori Crime
	e_public[10,0] = 10;
	e_alien[10,0] = -20;
	e_army[10,0] = 0;
	e_money[10,0] = 0;
	e_energy[10,0] = 0;
	e_public[10,1] = -10;
	e_alien[10,1] = -3;
	e_army[10,1] = 0;
	e_money[10,1] = 0;
	e_energy[10,1] = 0;
	e_public[10,2] = -20;
	e_alien[10,2] = 15;
	e_army[10,2] = 0;
	e_money[10,2] = 0;
	e_energy[10,2] = 0;
	e_public[10,3] = -5;
	e_alien[10,3] = -5;
	e_army[10,3] = 0;
	e_money[10,3] = -5;
	e_energy[10,3] = 0;
	// Terth Demands
	e_public[11,0] = -3;
	e_alien[11,0] = 0;
	e_army[11,0] = 3;
	e_money[11,0] = -8;
	e_energy[11,0] = 0;
	e_public[11,1] = 0;
	e_alien[11,1] = 0;
	e_army[11,1] = 8;
	e_money[11,1] = -10;
	e_energy[11,1] = 0;
	e_public[11,2] = 0;
	e_alien[11,2] = 0;
	e_army[11,2] = -15;
	e_money[11,2] = 10;
	e_energy[11,2] = 0;
	e_public[11,3] = -5;
	e_alien[11,3] = 0;
	e_army[11,3] = 2;
	e_money[11,3] = -5;
	e_energy[11,3] = 0;
	// Speed Enhancements
	e_public[12,0] = 3;
	e_alien[12,0] = 0;
	e_army[12,0] = 0;
	e_money[12,0] = 0;
	e_energy[12,0] = 0;
	e_public[12,1] = 8;
	e_alien[12,1] = 0;
	e_army[12,1] = 0;
	e_money[12,1] = -8;
	e_energy[12,1] = 0;
	e_public[12,2] = -10;
	e_alien[12,2] = 0;
	e_army[12,2] = 15;
	e_money[12,2] = -5;
	e_energy[12,2] = 0;
	e_public[12,3] = -8;
	e_alien[12,3] = 0;
	e_army[12,3] = 2;
	e_money[12,3] = 10;
	e_energy[12,3] = 0;
	// Power Formula
	e_public[13,0] = -8;
	e_alien[13,0] = 0;
	e_army[13,0] = 0;
	e_money[13,0] = 0;
	e_energy[13,0] = 8;
	e_public[13,1] = 2;
	e_alien[13,1] = 0;
	e_army[13,1] = 0;
	e_money[13,1] = -8;
	e_energy[13,1] = 12;
	e_public[13,2] = 0;
	e_alien[13,2] = 0;
	e_army[13,2] = 5;
	e_money[13,2] = -5;
	e_energy[13,2] = -3;
	e_public[13,3] = 0;
	e_alien[13,3] = 0;
	e_army[13,3] = 0;
	e_money[13,3] = 0;
	e_energy[13,3] = -3;
	// Terth War
	e_public[14,0] = 5;
	e_alien[14,0] = 0;
	e_army[14,0] = -15;
	e_money[14,0] = 0;
	e_energy[14,0] = 0;
	e_public[14,1] = -5;
	e_alien[14,1] = 0;
	e_army[14,1] = -8;
	e_money[14,1] = 0;
	e_energy[14,1] = 0;
	e_public[14,2] = 0;
	e_alien[14,2] = 0;
	e_army[14,2] = 0;
	e_money[14,2] = -10;
	e_energy[14,2] = 0;
	e_public[14,3] = 0;
	e_alien[14,3] = 0;
	e_army[14,3] = -2;
	e_money[14,3] = 0;
	e_energy[14,3] = -10;
	// Hospital Space
	e_public[15,0] = 5;
	e_alien[15,0] = 0;
	e_army[15,0] = 0;
	e_money[15,0] = -5;
	e_energy[15,0] = 0;
	e_public[15,1] = 18;
	e_alien[15,1] = 0;
	e_army[15,1] = 0;
	e_money[15,1] = -5;
	e_energy[15,1] = -10;
	e_public[15,2] = 0;
	e_alien[15,2] = 0;
	e_army[15,2] = 8;
	e_money[15,2] = -8;
	e_energy[15,2] = 0;
	e_public[15,3] = -10;
	e_alien[15,3] = 10;
	e_army[15,3] = 0;
	e_money[15,3] = 0;
	e_energy[15,3] = 0;
	// Ventori Gift
	e_public[16,0] = -3;
	e_alien[16,0] = 3;
	e_army[16,0] = 0;
	e_money[16,0] = 0;
	e_energy[16,0] = 7;
	e_public[16,1] = -3;
	e_alien[16,1] = 3;
	e_army[16,1] = 0;
	e_money[16,1] = 7;
	e_energy[16,1] = 0;
	e_public[16,2] = -3;
	e_alien[16,2] = 3;
	e_army[16,2] = 7;
	e_money[16,2] = 0;
	e_energy[16,2] = 0;
	e_public[16,3] = 3;
	e_alien[16,3] = -5;
	e_army[16,3] = 0;
	e_money[16,3] = 0;
	e_energy[16,3] = 0;
	// Sonic Tech
	e_public[17,0] = 0;
	e_alien[17,0] = 0;
	e_army[17,0] = 8;
	e_money[17,0] = -5;
	e_energy[17,0] = 0;
	e_public[17,1] = 8;
	e_alien[17,1] = 0;
	e_army[17,1] = 0;
	e_money[17,1] = -5;
	e_energy[17, 1] = 0;
	e_public[17,2] = 0;
	e_alien[17,2] = 0;
	e_army[17,2] = 0;
	e_money[17,2] = -5;
	e_energy[17,2] = 8;
	e_public[17,3] = 0;
	e_alien[17,3] = 0;
	e_army[17,3] = 0;
	e_money[17,3] = 5;
	e_energy[17,3] = 0;
	// Stolen Money
	e_public[18,0] = 0;
	e_alien[18,0] = 0;
	e_army[18,0] = -8;
	e_money[18,0] = 0;
	e_energy[18,0] = 0;
	e_public[18,1] = 3;
	e_alien[18,1] = 0;
	e_army[18,1] = 0;
	e_money[18,1] = -8;
	e_energy[18, 1] = 0;
	e_public[18,2] = -8;
	e_alien[18,2] = 0;
	e_army[18,2] = 0;
	e_money[18,2] = 2;
	e_energy[18,2] = 0;
	e_public[18,3] = -10;
	e_alien[18,3] = 5;
	e_army[18,3] = 0;
	e_money[18,3] = -2;
	e_energy[18,3] = 0;
	// Fugitives
	e_public[19,0] = -10;
	e_alien[19,0] = 0;
	e_army[19,0] = 0;
	e_money[19,0] = 5;
	e_energy[19,0] = 0;
	e_public[19,1] = 3;
	e_alien[19,1] = 0;
	e_army[19,1] = 0;
	e_money[19,1] = -3;
	e_energy[19, 1] = 0;
	e_public[19,2] = 7;
	e_alien[19,2] = 0;
	e_army[19,2] = 0;
	e_money[19,2] = -3;
	e_energy[19,2] = 0;
	e_public[19,3] = -1;
	e_alien[19,3] = 0;
	e_army[19,3] = 0;
	e_money[19,3] = -2;
	e_energy[19,3] = 0;
	// Filler
	e_public[20,0] = -5;
	e_alien[20,0] = 0;
	e_army[20,0] = 0;
	e_money[20,0] = 0;
	e_energy[20,0] = 0;
	e_public[20,1] = 0;
	e_alien[20,1] = 0;
	e_army[20,1] = 0;
	e_money[20,1] = 0;
	e_energy[20, 1] = -5;
	e_public[20,2] = 0;
	e_alien[20,2] = 0;
	e_army[20,2] = 0;
	e_money[20,2] = -5;
	e_energy[20,2] = 0;
	e_public[20,3] = 0;
	e_alien[20,3] = -5;
	e_army[20,3] = 0;
	e_money[20,3] = 0;
	e_energy[20,3] = 0;
	// Jerk Guy
	e_public[21,0] = 5;
	e_alien[21,0] = -10;
	e_army[21,0] = 0;
	e_money[21,0] = 0;
	e_energy[21,0] = 0;
	e_public[21,1] = -10;
	e_alien[21,1] = 5;
	e_army[21,1] = 0;
	e_money[21,1] = 0;
	e_energy[21, 1] = 0;
	e_public[21,2] = 0;
	e_alien[21,2] = -4;
	e_army[21,2] = 0;
	e_money[21,2] = 0;
	e_energy[21,2] = 0;
	e_public[21,3] = -1;
	e_alien[21,3] = -1;
	e_army[21,3] = 0;
	e_money[21,3] = -5;
	e_energy[21,3] = 0;


	// Draw the event and the choices
	if end_game != true {
	    draw_text_ext(100, 50, string_hash_to_newline(event[current_event]), -1, 800);
	} else {
	    if time >= 52 {
	        draw_text_ext(100, 50, string_hash_to_newline("You actually did it, I'm amazed. Connection with the mainland has been re-established, so everything's all nice and perfect and stuff now. But now they'll be in charge, so I guess you'll have to look for a new job. Oh well, I'm sure you'll be well compensated for your good work. Congrats. Have a virtual cookie."), -1, 800);
	        current_event = 1000
	        choices[1000, 0] = "Yay";
	        choices[1000, 1] = "Yay";
	        choices[1000, 2] = "Yay";
	        choices[1000, 3] = "Yay";
	    }
	    if public <= 0 {
	        draw_text_ext(100, 50, string_hash_to_newline("The people have gotten so displeased with your rule that they're revolting! The whole city is in anarchy!"), -1, 800);
	        current_event = 1000
	        choices[1000, 0] = "Aw";
	        choices[1000, 1] = "Aw";
	        choices[1000, 2] = "Aw";
	        choices[1000, 3] = "Aw";
	    }
	    if alien <= 0 {
	        draw_text_ext(100, 50, string_hash_to_newline("The Ventori have grown tired of you. So tired in fact, that they obliterated your entire city. Might want to stay on their good side next time."), -1, 800);
	        current_event = 1000
	        choices[1000, 0] = "Aw";
	        choices[1000, 1] = "Aw";
	        choices[1000, 2] = "Aw";
	        choices[1000, 3] = "Aw";
	    }
	    if army <= 0 {
	        draw_text_ext(100, 50, string_hash_to_newline("Your army was weak and the Terth noticed. And then they conquered your city. So now you get to be bossed around by slow, stupid aliens. Good work."), -1, 800);
	        current_event = 1000
	        choices[1000, 0] = "Aw";
	        choices[1000, 1] = "Aw";
	        choices[1000, 2] = "Aw";
	        choices[1000, 3] = "Aw";
	    }
	    if money <= 0 {
	        draw_text_ext(100, 50, string_hash_to_newline("You ran out of money, and shortly thereafter you ran out of evertything else. The whole city ended up getting bought out by various parties. So now you have nothing."), -1, 800);
	        current_event = 1000
	        choices[1000, 0] = "Aw";
	        choices[1000, 1] = "Aw";
	        choices[1000, 2] = "Aw";
	        choices[1000, 3] = "Aw";
	    }
	    if energy <= 0 {
	        draw_text_ext(100, 50, string_hash_to_newline("The power ran too low, and the whole city went into a blackout. Since everything's electronic now, you couldn't pay for anything, and the people quickly got so outraged that they revolted. And the shielding went down, so the only real battle to conquer your city was between the three alien races who now share it. You really messed this one up."), -1, 800);
	        current_event = 1000
	        choices[1000, 0] = "Aw";
	        choices[1000, 1] = "Aw";
	        choices[1000, 2] = "Aw";
	        choices[1000, 3] = "Aw";
	    }
	}

	var width;
	width = min(125, string_width(string_hash_to_newline(choices[current_event, 0])));
	draw_text_ext(650-width, 300, string_hash_to_newline(choices[current_event, 0]), -1, 250);
	width = min(125, string_width(string_hash_to_newline(choices[current_event, 1])));
	draw_text_ext(450-width, 450, string_hash_to_newline(choices[current_event, 1]), -1, 250);
	width = min(125, string_width(string_hash_to_newline(choices[current_event, 2])));
	draw_text_ext(850-width, 450, string_hash_to_newline(choices[current_event, 2]), -1, 250);
	width = min(125, string_width(string_hash_to_newline(choices[current_event, 3])));
	draw_text_ext(650-width, 600, string_hash_to_newline(choices[current_event, 3]), -1, 250);

	draw_text(930, 50, string_hash_to_newline("Week: " + string(time)));

	// Draw the status bars

	draw_text(40, 270, string_hash_to_newline("Public Opinion"));
	draw_healthbar(40, 300, 190, 315, public, c_white, c_red, c_blue, 0, true, true);
	draw_text(40, 350, string_hash_to_newline("Alien Opinion"));
	draw_healthbar(40, 380, 190, 395, alien, c_white, c_red, c_blue, 0, true, true);
	draw_text(40, 430, string_hash_to_newline("Army Strength"));
	draw_healthbar(40, 460, 190, 475, army, c_white, c_red, c_blue, 0, true, true);
	draw_text(40, 510, string_hash_to_newline("Availible Funds"));
	draw_healthbar(40, 540, 190, 555, money, c_white, c_red, c_blue, 0, true, true);
	draw_text(40, 590, string_hash_to_newline("City Energy Level"));
	draw_healthbar(40, 620, 190, 635, energy, c_white, c_red, c_blue, 0, true, true);

	// Check for the user input
	if keyboard_check_pressed(vk_enter) game_end();

	if keyboard_check_pressed(vk_up) option = 0;
	if keyboard_check_pressed(vk_left) option = 1;
	if keyboard_check_pressed(vk_right) option = 2;
	if keyboard_check_pressed(vk_down) option = 3;

	if option >= 0 and end_game == true {
	    game_end();
	} else if option >= 0 {
	    public += e_public[current_event, option];
	    alien += e_alien[current_event, option]
	    army += e_army[current_event, option]
	    money += e_money[current_event, option];
	    energy += e_energy[current_event, option]
	    option = -1;
    
	    if start == true {
	        if current_event < 5 {
	            current_event += 1;
	        }
	        else {
	            start = false;
	        }
	    } else {
	        time += 1;
	    }
	    if start == false {
	        current_event = irandom_range(6, array_length_1d(event)-1);
	    }
    
	    if time >= 52 {
	        end_game = true;
	    }
	    if public <= 0 or alien <= 0 or army <= 0 or money <= 0 or energy <= 0 {
	        end_game = true;
	    }

	}


	// Put the variables back in the list to be read from next game loop
	ds_list_replace(0, 0, current_event);
    
	ds_list_replace(0, 1, option);

	ds_list_replace(0, 2, public);
	ds_list_replace(0, 3, alien);
	ds_list_replace(0, 4, army);
	ds_list_replace(0, 5, money);
	ds_list_replace(0, 6, energy);

	ds_list_replace(0, 7, time);

	ds_list_replace(0, 8, start);
	ds_list_replace(0, 9, end_game);




}
