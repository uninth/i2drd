# Checkpoint Firewall regler der ikke anvendes

**i2drd** er et system til detektering af hvilke regler i et 
Check Point Firewewall regelsæt der ikke anvendes.

Systemet består af følgende komponenter:

  - En web-server: her anvendes basisprogrammel leveret med af Check Point
  - En samling programmer til
     - parsing af reglesæt databasen
	 - parsing af _den eksporterede logfil_
	 - konverting af data til hhv. _html_ og _csv_.

Adgang til serveren styres i firewall regelsættet.

Logfiler eksporteres én gang i døgnet (se dokumentation for programpakken
**UNItools**). Når processen er overstået starter **i2drd**'s analyse af
regelsættet.

# Oprydning

   - Inaktive regler anvendes ikke i regelsættet og har fået
     <html><span style="background-color:#FF9966;">denne farve (orange)</span></html>.
     De kan slettes med mindre de tjener et dokumentations- eller andet formål.
   - Regler uden hits siden start har fået <html><span style="background-color:#FFD6FF;">denne farve (pink)</span></html>. Hvis der er **slået logning til på reglen** bør man overveje om reglen tjener et formål.
   - Regler uden hits idag har fået <html><span style="background-color:#FFFFEE;">denne farve (vissen gul)</span> og bør undersøges</html>. Dato for sidste hit samt antal dage siden står i rapporten.

## Begrænsninger
Analysen har en række begrænsninger. Hvis f.eks. en regel ser sådan ud:

<html>
<table>
	<thead>
		<tr>
			<th>
				Nr.</th>
			<th>
				Source</th>
			<th>
				Destignation</th>
			<th>
				Service</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td>
				1</td>
			<td>
				internal_mail_1<br />
				internal_mail_2<br />
				<span style="background-color:#ffffe0;">monitor_host_1</span></td>
			<td>
				external_mail_1<br />
				external_mail_2</td>
			<td>
				SMTP<br />
				<span style="background-color:#ffffe0;">ICMP</span></td>
		</tr>
	</tbody>
</table>
</html>

Og der er f.eks. 100 hits på reglen, kan man ikke afgøre andet end at reglen bliver brugt.

Dvs. det kan være at det eneste der rammer reglen er ``monitor_host_1`` der
sender ``ICMP Echo Request`` mod ``external_mail_2`` og de andre maskiner er slukkede.

Det samme er tilfældet for regler der indeholder _grupper_, _ranges_ og netværk: det kan
være at det er en enkelt adresse der står for al trafikken.

# Rettigheder og det med småt

Systemet er ejet af [i2.dk](http://www.i2.dk) og må kun anvendes af kunder
med en gyldig firewall driftaftale med i2.dk.

i2.dk har skrevet og dermed ejerskab til al programmel, mens data i form af
rapporter tilhører kunden. Kopiering af programmel er ikke tilladt.


