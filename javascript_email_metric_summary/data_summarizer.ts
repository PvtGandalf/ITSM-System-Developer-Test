import * as fs from "fs";

const TICKET_DATA_SOURCE = "TypeScript_Source_Data.json";

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

// Function to read the JSON file with error handling
const readJsonFile = (filePath: string): Ticket[] => {
  try {
    const rawData = fs.readFileSync(filePath, "utf-8");
    return JSON.parse(rawData);
  } catch (error) {
    console.error("Error reading or parsing JSON file:", error);
    return [];
  }
};

// Function to aggregate data by team
const aggregateDataByTeam = (tickets: Ticket[]) => {
  const teamSummary: {
    [key: string]: {
      totalTickets: number;
      totalTimeToResolve: number;
      totalCustomerSatisfaction: number;
    };
  } = {};

  tickets.forEach((ticket) => {
    const team = ticket.assigned_team;
    const timeToResolve = parseInt(ticket.time_to_resolve);
    const customerSatisfaction = parseInt(ticket.customer_satisfaction_rating);

    // Initialize team if not yet created
    if (!teamSummary[team]) {
      teamSummary[team] = {
        totalTickets: 0,
        totalTimeToResolve: 0,
        totalCustomerSatisfaction: 0,
      };
    }

    teamSummary[team].totalTickets++;
    teamSummary[team].totalTimeToResolve += timeToResolve;
    teamSummary[team].totalCustomerSatisfaction += customerSatisfaction;
  });

  // Calculate averages
  Object.keys(teamSummary).forEach((team) => {
    const teamData = teamSummary[team];
    teamData.totalTimeToResolve /= teamData.totalTickets;
    teamData.totalCustomerSatisfaction /= teamData.totalTickets;
  });

  // Sort teams by totalTickets in descending order
  const sortedTeamSummary = Object.keys(teamSummary)
    .sort((a, b) => teamSummary[b].totalTickets - teamSummary[a].totalTickets)
    .reduce((sortedSummary, team) => {
      sortedSummary[team] = teamSummary[team];
      return sortedSummary;
    }, {} as typeof teamSummary);

  return sortedTeamSummary;
};

// Function to generate the table header
const generateTableHeader = () => `
  <thead>
    <tr>
      <th>Team</th>
      <th>Total Tickets</th>
      <th>Avg Time to Resolve (hrs)</th>
      <th>Avg Customer Satisfaction</th>
    </tr>
  </thead>
`;

// Function to generate table rows
const generateTableRow = (
  team: string,
  teamData: {
    totalTickets: number;
    totalTimeToResolve: number;
    totalCustomerSatisfaction: number;
  }
) => {
  const avgTimeToResolve = (teamData.totalTimeToResolve / 60).toFixed(2); // Convert minutes to hours
  const avgCustomerSatisfaction = teamData.totalCustomerSatisfaction.toFixed(2);
  return `
  <tr>
    <td>${team}</td>
    <td>${teamData.totalTickets}</td>
    <td>${avgTimeToResolve}</td>
    <td>${avgCustomerSatisfaction}</td>
  </tr>`;
};

// Function to generate the HTML table
const generateHtmlTable = (teamSummary: {
  [key: string]: {
    totalTickets: number;
    totalTimeToResolve: number;
    totalCustomerSatisfaction: number;
  };
}) => {
  let tableHtml = `<table border="1" style="border-collapse: collapse; width: 100%; margin-top: 20px;">`;
  tableHtml += generateTableHeader();

  tableHtml += `<tbody>`;

  // Iterating over the sorted team summary
  Object.keys(teamSummary).forEach((team) => {
    const teamData = teamSummary[team];
    tableHtml += generateTableRow(team, teamData);
  });

  tableHtml += `</tbody></table>`;
  return tableHtml;
};

// Function to generate the email message
const generateEmailMessage = (teamSummary: {
  [key: string]: {
    totalTickets: number;
    totalTimeToResolve: number;
    totalCustomerSatisfaction: number;
  };
}) => {
  const subject = "Team Performance Summary";
  const body = `
    <h1>Team Performance Summary</h1>
    <p>Below is the summary of the performance for each team:</p>
    ${generateHtmlTable(teamSummary)}
  `;

  return { subject, body };
};

// Main execution
const tickets = readJsonFile(TICKET_DATA_SOURCE);
const teamSummary = aggregateDataByTeam(tickets);
const emailMessage = generateEmailMessage(teamSummary);

// Output the email message (you could replace this with actual email sending logic)
console.log("Subject:", emailMessage.subject);
console.log("Body:", emailMessage.body);
