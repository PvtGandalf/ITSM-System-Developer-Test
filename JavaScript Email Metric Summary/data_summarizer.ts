import * as fs from 'fs';

// Interface for the ticket data
interface Ticket {
    ticket_id: string;
    ticket_created_at: string;
    ticket_resolved_at: string;
    time_to_resolve: string;
    assigned_team: string;
    ticket_category: string;
    ticket_priority: string;
    resolution_notes: string;
    customer_satisfaction_rating: string;
}

// Function to read the JSON file
const readJsonFile = (filePath: string): Ticket[] => {
    const rawData = fs.readFileSync(filePath, 'utf-8');
    return JSON.parse(rawData);
};

// Function to aggregate data by team
const aggregateDataByTeam = (tickets: Ticket[]) => {
    const teamSummary: { [key: string]: { totalTickets: number, totalTimeToResolve: number, totalCustomerSatisfaction: number } } = {};

    tickets.forEach(ticket => {
        const team = ticket.assigned_team;
        const timeToResolve = parseInt(ticket.time_to_resolve);
        const customerSatisfaction = parseInt(ticket.customer_satisfaction_rating);

        if (!teamSummary[team]) {
            teamSummary[team] = { totalTickets: 0, totalTimeToResolve: 0, totalCustomerSatisfaction: 0 };
        }

        teamSummary[team].totalTickets += 1;
        teamSummary[team].totalTimeToResolve += timeToResolve;
        teamSummary[team].totalCustomerSatisfaction += customerSatisfaction;
    });

    // Calculate averages
    Object.keys(teamSummary).forEach(team => {
        const teamData = teamSummary[team];
        teamData.totalTimeToResolve = teamData.totalTimeToResolve / teamData.totalTickets;
        teamData.totalCustomerSatisfaction = teamData.totalCustomerSatisfaction / teamData.totalTickets;
    });

    return teamSummary;
};

// Function to generate an HTML table for the email body
const generateHtmlTable = (teamSummary: { [key: string]: { totalTickets: number, totalTimeToResolve: number, totalCustomerSatisfaction: number } }) => {
    let tableHtml = `<table border="1" style="border-collapse: collapse; width: 100%; margin-top: 20px;">
                        <thead>
                            <tr>
                                <th>Team</th>
                                <th>Total Tickets</th>
                                <th>Avg Time to Resolve (hrs)</th>
                                <th>Avg Customer Satisfaction</th>
                            </tr>
                        </thead>
                        <tbody>`;

    Object.keys(teamSummary).forEach(team => {
        const teamData = teamSummary[team];
        tableHtml += `<tr>
                        <td>${team}</td>
                        <td>${teamData.totalTickets}</td>
                        <td>${(teamData.totalTimeToResolve / 60).toFixed(2)}</td> <!-- Convert minutes to hours -->
                        <td>${teamData.totalCustomerSatisfaction.toFixed(2)}</td>
                      </tr>`;
    });

    tableHtml += `</tbody></table>`;
    return tableHtml;
};

// Function to generate the email message
const generateEmailMessage = (teamSummary: { [key: string]: { totalTickets: number, totalTimeToResolve: number, totalCustomerSatisfaction: number } }) => {
    const subject = 'Team Performance Summary';
    const body = `
        <h1>Team Performance Summary</h1>
        <p>Below is the summary of the performance for each team:</p>
        ${generateHtmlTable(teamSummary)}
    `;

    return { subject, body };
};

// Main execution
const tickets = readJsonFile('TypeScript_Source_Data.json'); // Path to the JSON file
const teamSummary = aggregateDataByTeam(tickets);
const emailMessage = generateEmailMessage(teamSummary);

// Output the email message (you could replace this with actual email sending logic)
console.log('Subject:', emailMessage.subject);
console.log('Body:', emailMessage.body);
